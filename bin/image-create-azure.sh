#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

IMG_VERSION="v040b1"
IMAGE_NAME="kubenow-$IMG_VERSION"
RESOURCE_GROUP="kubenow-images-rg"
SRC_CONTAINER="https://kubenow.blob.core.windows.net/system"
TF_VARS_FILE=${1:-terraform.tfvars}

# Get vars from tfvars-file
# ARM_CLIENT_ID=$(json2hcl -reverse < "$TF_VARS_FILE" | jq --raw-output '.client_id')
ARM_CLIENT_ID=$(grep "client_id" "$TF_VARS_FILE" | cut -d "=" -f 2- | awk -F\" '{print $(NF-1)}')
ARM_CLIENT_SECRET=$(grep "client_secret" "$TF_VARS_FILE" | cut -d "=" -f 2- | awk -F\" '{print $(NF-1)}')
ARM_TENANT_ID=$(grep "tenant_id" "$TF_VARS_FILE" | cut -d "=" -f 2- | awk -F\" '{print $(NF-1)}')
LOCATION=$(grep "location" "$TF_VARS_FILE" | cut -d "=" -f 2- | awk -F\" '{print $(NF-1)}')

CMD_OUTPUT_FMT="table"

echo "Login"
az login --service-principal \
         -u "$ARM_CLIENT_ID" \
         -p "$ARM_CLIENT_SECRET" \
         --tenant "$ARM_TENANT_ID" \
         --output "$CMD_OUTPUT_FMT"

echo "Check if image already exists"
image_details=$(az image show --resource-group "$RESOURCE_GROUP" --name "$IMAGE_NAME")
if [ -z "$image_details" ]; then

  echo "Image is not present in this subscription - will create"

  echo "Create resource-group (if not there already)"
  az group create --location "$LOCATION" \
                  --name "$RESOURCE_GROUP" \
                  --output "$CMD_OUTPUT_FMT"

  echo "Create storage account (if not there already)"
  # create a uniqe (>1 in a quadrillion), and stable suffix via md5sum of subscription-id
  subscription_id=$(az account show --query id | tr -d '"')
  suffix=$(md5sum <<< "$subscription_id" | head -c 14)
  storage_account="kubenow000$suffix"
  az storage account create --name "$storage_account" \
                            --resource-group "$RESOURCE_GROUP" \
                            --sku Standard_LRS \
                            --output "$CMD_OUTPUT_FMT"

  echo "Create storage container (if not there already)"
  az storage container create --name kubenow-images \
                              --account-name "$storage_account" \
                              --output "$CMD_OUTPUT_FMT"

  echo "Get uri of files to copy"
  file_name_json=$(az storage blob list --account-name kubenow \
                                        --container-name system \
                                        --query [].name \
                                        --output tsv |
                                        grep "/$IMAGE_NAME/.*json")

  file_name_vhd=$(az storage blob list --account-name kubenow \
                                       --container-name system \
                                       --query [].name \
                                       --output tsv |
                                       grep "/$IMAGE_NAME/.*vhd")
  
  echo "$SRC_CONTAINER/$file_name_vhd"

  echo "Start asynchronous file copy of image def file"
  echo az storage blob copy start --account-name "$storage_account" \
                             --destination-blob "$file_name_json" \
                             --destination-container kubenow-images \
                             --source-uri "$SRC_CONTAINER/$file_name_json" \
                             --output "$CMD_OUTPUT_FMT"

  echo "Start asynchronous file copy of VHD-file"
  az storage blob copy start --account-name "$storage_account" \
                             --destination-blob "$file_name_vhd" \
                             --destination-container kubenow-images \
                             --source-uri "$SRC_CONTAINER/$file_name_vhd" \
                             --output "$CMD_OUTPUT_FMT" &&
                             true

  # check file copy status
  spin='-\|/'
  for i in {0..36000}; do
    n=$(( i %4 ))
    m=$(( i %6 ))
    if [ $m == 0 ]; then
      progress=$(az storage blob show --name "$file_name_vhd" \
                                      --container-name kubenow-images \
                                      --account-name "$storage_account" \
                                      --query properties.copy.progress |
                                      tr -d '"')

      done_bytes=$(echo "$progress" | cut -d '/' -f 1)
      total_bytes=$(echo "$progress" | cut -d '/' -f 2)
      # The total bytes show actual file size, but since only about 3.5GB of 30GB is being
      # used, the last 26.5GB is zero-filled and copied instantly, then file copy progress displayed
      # to user would be very skewed if not adjusted down to display used bytes)
      ACTUAL_IMAGE_FILE_SIZE=3450000000
      percent=$( bc -l <<< "($done_bytes/$ACTUAL_IMAGE_FILE_SIZE)*100" )
      # Never more than 99.99% (this could happen when ACTUAL_IMAGE_FILE_SIZE is set to small)
      percent=$( bc -l <<< "if ($percent > 100) 99.99 else $percent")
    fi

    printf '\r %s Image copy progress: %.2f%%' "${spin:$n:1}" "$percent"

    # Break when finished
    if [[ "$done_bytes" == "$total_bytes" ]]; then
      printf '\rDone copy image                   \n'
      break
    fi

    sleep 0.6;
  done

  echo "Create image from imported vhd-file"
  az image create --resource-group "$RESOURCE_GROUP" \
                  --name "$IMAGE_NAME" \
                  --os-type "Linux" \
                  --source "https://$storage_account.blob.core.windows.net/kubenow-images/$file_name_vhd" \
                  --output "$CMD_OUTPUT_FMT"

  echo "Image created"

else
  echo "Image exists - no need to create"
fi
