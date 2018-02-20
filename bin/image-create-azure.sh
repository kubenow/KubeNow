#!/usr/bin/env bash
#
# Checks and uploads specified Image to user's Azure account.
# Uses azure command line client to do the job.
# The image will be uploaded to a generated resource-group in
# a generated storage-account in a speciffic location
#
# Env vars (mandatory)
#   KN_IMAGE_NAME
#   TF_VARS_FILE

# Exit immediately if a command exits with a non-zero status
set -e

echo "Started script image-create-azure"

RESOURCE_GROUP_PREFIX="kubenow-images-rg"
SRC_CONTAINER="https://kubenow.blob.core.windows.net/system"
OUTPUT_FMT="table"

if [ -z "$KN_IMAGE_NAME" ]; then
  echo >&2 "env KN_IMAGE_NAME must be set for this script to run"
  exit 1
fi

if [ -z "${TF_VARS_FILE}" ]; then
  echo >&2 "env TF_VARS_FILE must be set for this script to run"
fi

# Get vars from tfvars-file
arm_client_id=$(grep "^client_id" "$TF_VARS_FILE" |
  cut -d "=" -f 2- |
  awk -F\" '{print $(NF-1)}')

arm_client_secret=$(grep "^client_secret" "$TF_VARS_FILE" |
  cut -d "=" -f 2- |
  awk -F\" '{print $(NF-1)}')

arm_tenant_id=$(grep "^tenant_id" "$TF_VARS_FILE" |
  cut -d "=" -f 2- |
  awk -F\" '{print $(NF-1)}')

arm_location=$(grep "^location" "$TF_VARS_FILE" |
  cut -d "=" -f 2- |
  awk -F\" '{print $(NF-1)}')

echo "Login"
az login --service-principal \
  -u "$arm_client_id" \
  -p "$arm_client_secret" \
  --tenant "$arm_tenant_id" \
  --output "$OUTPUT_FMT"

# Make sure location is in lowercase format without spaces
location_short="${arm_location//[[:blank:]]/}"
location_short="${location_short,,}"

# append location to rg to make unique rg per location
resource_group="$RESOURCE_GROUP_PREFIX-$location_short"

# Check if image exists in this resource-group in this location
image_details=$(az image show --resource-group "$resource_group" --name "$KN_IMAGE_NAME" -o json |
  jq "select(.location == \"$location_short\")")
if [ -z "$image_details" ]; then

  echo "Image is not present in this subscription - will create"

  echo "Create resource-group (if not there already)"
  az group create --location "$location_short" \
    --name "$resource_group" \
    --output "$OUTPUT_FMT"

  echo "Create storage account (if not there already)"
  # Azure storage account names need to be unique.
  # Create a uniqe (>1 in a quadrillion), and stable suffix via
  # md5sum of subscription-id + location
  subscription_id=$(az account show --query id | tr -d '"')
  suffix=$(md5sum <<<"$subscription_id$location_short" | head -c 14)
  storage_account="kubenow000$suffix"
  az storage account create --name "$storage_account" \
    --resource-group "$resource_group" \
    --sku Standard_LRS \
    --output "$OUTPUT_FMT"

  echo "Create storage container (if not there already)"
  az storage container create --name kubenow-images \
    --account-name "$storage_account" \
    --output "$OUTPUT_FMT"

  echo "Get uri of files to copy"
  file_name_json=$(az storage blob list --account-name kubenow \
    --container-name system \
    --query [].name \
    --output tsv |
    grep "/$KN_IMAGE_NAME/.*json")

  file_name_vhd=$(az storage blob list --account-name kubenow \
    --container-name system \
    --query [].name \
    --output tsv |
    grep "/$KN_IMAGE_NAME/.*vhd")

  echo "Start asynchronous file copy of image def file"
  az storage blob copy start --account-name "$storage_account" \
    --destination-blob "$file_name_json" \
    --destination-container kubenow-images \
    --source-uri "$SRC_CONTAINER/$file_name_json" \
    --output "$OUTPUT_FMT"

  echo "Start asynchronous file copy of VHD-file"
  az storage blob copy start --account-name "$storage_account" \
    --destination-blob "$file_name_vhd" \
    --destination-container kubenow-images \
    --source-uri "$SRC_CONTAINER/$file_name_vhd" \
    --output "$OUTPUT_FMT" &&
    true

  # Check file copy progress by polling the show blob status.
  # This loop also updates the copy progress message to user and
  # updates the spinner character
  spin='-\|/'
  for i in {0..36000}; do
    n=$((i % 4))
    m=$((i % 6))

    # Every m time poll copy progress
    if [ $m == 0 ]; then
      progress=$(az storage blob show --name "$file_name_vhd" \
        --container-name kubenow-images \
        --account-name "$storage_account" \
        --query properties.copy.progress |
        tr -d '"')

      done_bytes=$(echo "$progress" | cut -d '/' -f 1)
      total_bytes=$(echo "$progress" | cut -d '/' -f 2)
      percent=$(bc -l <<<"($done_bytes/$total_bytes)*100")
      done_mbytes=$(bc -l <<<"($done_bytes/1000000)")
      total_mbytes=$(bc -l <<<"($total_bytes/1000000)")
    fi

    # Every time print status message with an updated spinner symbol
    printf '\r %s Image copy progress: %.2f%% %.2f / %.2f MB (sometimes the copy process is much faster after ca 10%%)' "${spin:$n:1}" "$percent" "$done_mbytes" "$total_mbytes"

    # Break when finished
    if [[ "$done_bytes" == "$total_bytes" ]]; then
      printf '\rDone copy image                                                                                                  \n'
      break
    fi

    sleep 0.6
  done

  echo "Create image from imported vhd-file"
  az image create --resource-group "$resource_group" \
    --name "$KN_IMAGE_NAME" \
    --os-type "Linux" \
    --source "https://$storage_account.blob.core.windows.net/kubenow-images/$file_name_vhd" \
    --output "$OUTPUT_FMT"

  echo "Image created"

else
  echo "Image exists - no need to create"
fi
