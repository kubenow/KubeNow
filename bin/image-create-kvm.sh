#!/usr/bin/env bash

# Downloads image from an Amazon S3 storage account to host local directory
#
# Env vars
#   KN_IMAGE_NAME
#   KN_IMAGE_BUCKET_URL

# Exit immediately if a command exits with a non-zero status
set -e

function is_checksum_ok() {
  echo "Verify checksum"
  # local source_file="$1"
  echo 0
}

function download_checksum_file() {
  echo "Download checksum"
  # local source_file="$1"
  echo 0
}

function download_image() {
  local file_url="$1"
  local dest_dir="$2"
  local file_name="$3"

  echo "Downloading image $file_name to $dest_dir"

  mkdir -p "$dest_dir"
  curl "$file_url" \
    -o "$dest_dir/$file_name" \
    --connect-timeout 30 \
    --max-time 1800
}

echo "Started script image-create-kvm"

if [ -z "$KN_IMAGE_NAME" ]; then
  echo >&2 "env KN_IMAGE_NAME must be set for this script to run"
  exit 1
fi

KN_IMAGE_BUCKET_URL=${KN_IMAGE_BUCKET_URL:-"https://s3.eu-central-1.amazonaws.com/kubenow-eu-central-1"}
file_name="$KN_IMAGE_NAME"
local_dir=${KN_LOCAL_DIR:="kvm-image"}
temp_dir="/tmp/kvm-image"

# Add .qcow suffix if it is a KubeNow image
if [[ "$file_name" == kubenow* ]]; then
  file_name="$file_name.qcow"
fi

# Check if file exist
if [ -f "$temp_dir/$file_name" ]; then
  # Check if checksum ok
  if is_checksum_ok; then
    echo "File exists, checksum is OK."
    
    # move image to final dest if not there
    if [ ! -f "$local_dir/$file_name" ]; then
      echo "Copy file to $local_dir/$file_name"
      mkdir -p "$local_dir"
      cp "$temp_dir/$file_name" "$local_dir/$file_name"
      exit 0
    else
      echo "File exists in final dir"
      exit 0
    fi
  else
    echo "File exists, checksum is wrong, continuing..."
  fi
else
  echo "File does not exist localy"
fi

# Download image
download_image "$KN_IMAGE_BUCKET_URL/$file_name" "$temp_dir" "$file_name"

if [ ! -f "$temp_dir/$file_name" ]; then
  echo "Could not download file ok"
  exit 1
fi

if ! is_checksum_ok; then
  echo "Checksum of downloaded file is not correct"
  exit 1
fi

# Move image to final dest
echo "Copy file to $local_dir/$file_name"
mkdir -p "$local_dir"
cp "$temp_dir/$file_name" "$local_dir/$file_name"


