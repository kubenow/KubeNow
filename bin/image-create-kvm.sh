#!/usr/bin/env bash

# Downloads image from an Amazon S3 storage account to host local directory
#
# Env vars
#   KN_IMAGE_NAME
#   KN_IMAGE_BUCKET_URL

# Exit immediately if a command exits with a non-zero status
set -e

function is_checksum_ok() {
  local checksum="$1"
  local source_file="$2"
  
  echo "Verify checksum"
  
  sha256result=$(
    sha256sum -c <<< "$checksum $source_file"
  )
  
  if [[ "$sha256result" != *": OK"* ]]; then
    return 1
  else
    return 0
  fi
}

function download_image() {
  local file_url="$1"
  local dest_dir="$2"
  local file_name="$3"
  
  if [ ! -f "$dest_dir/$file_name" ]; then
    echo "Downloading image $file_name to $dest_dir"
    mkdir -p "$dest_dir"
    curl "$file_url" \
      -o "$dest_dir/$file_name" \
      --fail \
      --connect-timeout 30 \
      --max-time 1800
  fi
  
  return 0
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
checksum="$KN_IMAGE_SHA256_SUM"

# Add .qcow suffix if it is a KubeNow image
if [[ "$file_name" == kubenow* ]]; then
  file_name="$file_name.qcow"
fi

# check if file is in final dir
if [ -f "$local_dir/$file_name" ]; then
  echo "File exists in final dir"
  
  # Checksum
  if [ -n "$KN_IMAGE_SHA256_SUM" ]; then
    if is_checksum_ok "$checksum" "$local_dir/$file_name"; then
      echo "Checksum is ok"
    else
      echo "Checksum of file: $local_dir/$file_name is wrong, exiting"
      exit 1
    fi
  fi
  
  exit 0
fi

# Download if needed
if [ ! -f "$temp_dir/$file_name" ]; then
  # Download image
  download_image "$KN_IMAGE_BUCKET_URL/$file_name" "$temp_dir" "$file_name" "$checksum"
fi

# Checksum
if [ -n "$KN_IMAGE_SHA256_SUM" ]; then
  if is_checksum_ok "$checksum" "$temp_dir/$file_name"; then
    echo "Checksum is ok"
  else
    echo "Checksum of downloaded file: $temp_dir/$file_name is wrong, exiting"
    exit 1
  fi
fi

# Move image to final dest
echo "Copy file to $local_dir/$file_name"
mkdir -p "$local_dir"
cp "$temp_dir/$file_name" "$local_dir/$file_name"

# Checksum
if [ -n "$KN_IMAGE_SHA256_SUM" ]; then
  if is_checksum_ok "$checksum" "$local_dir/$file_name"; then
    echo "Checksum is ok"
  else
    echo "Checksum of file: $local_dir/$file_name is wrong, exiting"
    exit 1
  fi
fi
