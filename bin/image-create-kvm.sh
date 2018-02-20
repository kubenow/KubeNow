#!/usr/bin/env bash

# Downloads image from an Amazon S3 storage account to host local directory
#
# Env vars
#   KN_IMAGE_NAME
#   KN_IMAGE_BUCKET_URL

# Exit immediately if a command exits with a non-zero status
#set -e

echo "Started script image-create-kvm"

if [ -z "$KN_IMAGE_NAME" ]; then
  echo >&2 "env KN_IMAGE_NAME must be set for this script to run"
  exit 1
fi

KN_IMAGE_BUCKET_URL=${KN_IMAGE_BUCKET_URL:-"https://s3.eu-central-1.amazonaws.com/kubenow-eu-central-1"}
file_name="$KN_IMAGE_NAME.qcow2"
local_dir=${KN_LOCAL_DIR:="kvm-image"}

# check if image is present locally already (then also verify md5 sum)
if [ -e "$local_dir/$file_name" ] && [ -e "$local_dir/$file_name.md5" ]; then
  echo "Check md5 sum"
  md5only=$(cut -f1 -d ' ' "$local_dir/$file_name.md5")
  if md5sum -c <<<"$md5only  $local_dir/$file_name"; then
    echo "File exists, checksum is OK. Exit"
    exit 0
  else
    echo "File exists, checksum is wrong, continuing..."
  fi
else
  echo "File does not exist localy"
fi

# Make sure file exists on server
response=$(curl "$KN_IMAGE_BUCKET_URL/$file_name" \
  --connect-timeout 30 \
  --max-time 1800 \
  --head \
  --write-out "%{http_code}" \
  --silent \
  --output /dev/null)

if [[ "$response" != 200 ]]; then
  if [[ "$response" == 404 ]]; then
    echo "Error from download server: File not found: $KN_IMAGE_BUCKET_URL/$file_name"
    exit 1
  else
    echo "Error code from download server: $KN_IMAGE_BUCKET_URL/$file_name"
    exit 1
  fi
else
  echo "File eists on server $KN_IMAGE_BUCKET_URL"
fi

echo "Downloading image to local dir $local_dir"

mkdir -p "$local_dir"
curl "$KN_IMAGE_BUCKET_URL/$file_name" \
  -o "$local_dir/$file_name" \
  --connect-timeout 30 \
  --max-time 1800

echo "Download md5 sum file"
curl "$KN_IMAGE_BUCKET_URL/$file_name.md5" \
  -o "$local_dir/$file_name.md5" \
  --connect-timeout 30 \
  --max-time 1800

echo "Check md5 sum"
md5only=$(cut -f1 -d ' ' "$local_dir/$file_name.md5")
if md5sum -c <<<"$md5only  $local_dir/$file_name"; then
  echo "Checksum is OK"
else
  echo "Checksum is wrong. Downloading image has failed - please try running again. Exit"
  exit 1
fi

echo "Cleaning up old KuneNow images in local folder"
# find and rm all images (and md5 files) but not current one
find "$local_dir" -name 'kubenow-*.qcow*' ! -name "$file_name*" -exec rm {} \;
