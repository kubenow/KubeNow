#!/usr/bin/env bash

# Checks and uploads specified Image to user's OpenStack account.
# Downloads image first from an Amazon S3 storage account to host,
# then uploads image to openstack teenancy.
# Uses curl and python-glanceclient to do the job.
#
# Env vars
#   KN_IMAGE_NAME
#   KN_IMAGE_BUCKET_URL

# Exit immediately if a command exits with a non-zero status
set -e

echo "Started script image-create-openstack"

if [ -z "$KN_IMAGE_NAME" ]; then
  echo >&2 "env KN_IMAGE_NAME must be set for this script to run"
  exit 1
fi

KN_IMAGE_BUCKET_URL=${KN_IMAGE_BUCKET_URL:-"https://s3.eu-central-1.amazonaws.com/kubenow-eu-central-1"}
file_name="$KN_IMAGE_NAME.qcow2"

# Check if image is present already
echo "List images available in OpenStack..."
image_list="$(glance image-list)"
image_id="$(printf '%s' "$image_list" |
  grep "\s$KN_IMAGE_NAME\s" |
  awk -F "|" '{print $2;}' |
  tr -d '[:space:]')"

# If it exist then exit here
if [ -n "$image_id" ]; then
  echo "file exists - no need to upload, exit image-upload script"
  exit 0
fi

# If it doesn't exist then download it
echo "Image not present in OpenStack"
echo "Downloading image to local /tmp/"
curl "$KN_IMAGE_BUCKET_URL/$file_name" \
  -o "/tmp/$file_name" \
  --connect-timeout 30 \
  --max-time 1800

echo "Download md5 sum file"
curl "$KN_IMAGE_BUCKET_URL/$file_name.md5" \
  -o "/tmp/$file_name.md5" \
  --connect-timeout 30 \
  --max-time 1800

# Verify md5sum of downloaded file
echo "Check md5 sum"
md5result=$(
  cd /tmp
  md5sum -c "$file_name.md5"
)
if [[ "$md5result" != *": OK"* ]]; then
  echo >&2 "Wrong checksum of downloaded image."
  echo >&2 "Something might have failed on file transfer."
  echo >&2 "Please try again."
  exit 1
else
  echo "Checksum of downloaded image OK"
fi

# Upload image
echo "Uploading image"
glance image-create \
  --file "/tmp/$file_name" \
  --disk-format qcow2 \
  --min-disk 20 \
  --container-format bare \
  --name "$KN_IMAGE_NAME" \
  --progress

echo "Verify md5 of present/uploaded image..."
echo "List images available in OpenStack..."
image_list="$(glance image-list)"
image_id="$(printf '%s' "$image_list" |
  grep "\s$KN_IMAGE_NAME\s" |
  awk -F "|" '{print $2;}' |
  tr -d '[:space:]')"

# Get checksum of uploaded file
image_details="$(glance image-show "$image_id")"
checksum="$(printf '%s' "$image_details" |
  grep -w "checksum" |
  awk -F "|" '{print $3;}' |
  tr -d '[:space:]')"

# Get checksum of bucket image
echo "Download md5 sum file"
curl "$KN_IMAGE_BUCKET_URL/$file_name.md5" \
  -o "/tmp/$file_name.md5" \
  --connect-timeout 30 \
  --max-time 1800

md5only=$(cut -f1 -d ' ' "/tmp/$file_name.md5")
if [ "$md5only" != "$checksum" ]; then
  echo >&2 "Wrong checksum of present/uploaded image."
  echo >&2 "Something might have failed on file transfer."
  echo >&2 "Please delete image $KN_IMAGE_NAME from Openstack and try again."
  exit 1
else
  echo "Checksum OK"
fi

echo "Image upload done"
