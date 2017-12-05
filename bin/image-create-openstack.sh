#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

if [ -z "$IMAGE_NAME" ]; then
  >&2 echo "env IMAGE_NAME must be set for this script to run"
  exit 1
fi

IMAGE_BUCKET_URL=${IMAGE_BUCKET_URL:-"https://s3.eu-central-1.amazonaws.com/kubenow-eu-central-1"}
FILE_NAME="$IMAGE_NAME.qcow2"


# check if image is present already
echo "List images available in OpenStack..."
image_list="$(glance image-list)"
image_id="$(printf '%s' "$image_list" | \
            grep "\s$IMAGE_NAME\s" | \
            awk -F "|" '{print $2;}' | \
            tr -d '[:space:]')"

# if it doesn't exist then download it
if [ -z "$image_id" ]; then
  echo "Image not present in OpenStack"
  echo "Downloading image to local /tmp/"
  curl "$IMAGE_BUCKET_URL/$FILE_NAME" \
       -o "/tmp/$FILE_NAME" \
       --connect-timeout 30 \
       --max-time 1800

  echo "Download md5 sum file"
  curl "$IMAGE_BUCKET_URL/$FILE_NAME.md5" \
       -o "/tmp/$FILE_NAME.md5" \
       --connect-timeout 30 \
       --max-time 1800

  echo "Check md5 sum"
  md5only=$( cut -f1 -d ' ' "/tmp/$FILE_NAME.md5")
  printf '%s' "$md5only  /tmp/$FILE_NAME" | md5sum -c
else
  echo "File exists - no need to download"
fi

# if it didn't exist then upload it
if [ -z "$image_id" ]; then
  echo "Uploading image"
  glance image-create \
      --file "/tmp/$FILE_NAME" \
      --disk-format qcow2 \
      --min-disk 20 \
      --container-format bare \
      --name "$IMAGE_NAME" \
      --progress
else
  echo "file exists - no need to upload"
fi

echo "Verify md5 of present/uploaded image..."
echo "List images available in OpenStack..."
image_list="$(glance image-list)"
image_id="$(printf '%s' "$image_list" | \
            grep "\s$IMAGE_NAME\s" | \
            awk -F "|" '{print $2;}' | \
            tr -d '[:space:]')"

# Get checksum of uploaded file
image_details="$(glance image-show "$image_id")"
checksum="$(printf '%s' "$image_details" | \
            grep -w "checksum" | \
            awk -F "|" '{print $3;}' | \
            tr -d '[:space:]')"

# Get checksum of bucket image
echo "Download md5 sum file"
curl "$IMAGE_BUCKET_URL/$FILE_NAME.md5" \
       -o "/tmp/$FILE_NAME.md5" \
       --connect-timeout 30 \
       --max-time 1800

md5only=$( cut -f1 -d ' ' "/tmp/$FILE_NAME.md5")
if [ "$md5only" != "$checksum" ]; then
  >&2 echo "Wrong checksum of present/uploaded image."
  >&2 echo "Something might have failed on file transfer."
  >&2 echo "Please delete image $IMAGE_NAME from Openstack and try again."
  exit 1
else
  echo "Checksum OK"
fi

echo "Image upload done"
