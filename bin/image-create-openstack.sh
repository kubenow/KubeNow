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

source ./openstack/functions.sh

echo "Started script image-create-openstack"

if [ -z "$KN_IMAGE_NAME" ]; then
  echo >&2 "env KN_IMAGE_NAME must be set for this script to run"
  exit 1
fi

if [ -z "${KN_DISC_FORMAT}" ]; then
  echo >&2 "env KN_DISC_FORMAT must be set for this script to run"
  exit 1
fi


KN_IMAGE_BUCKET_URL=${KN_IMAGE_BUCKET_URL:-"https://s3.eu-central-1.amazonaws.com/kubenow-eu-central-1"}
download_file_name="${KN_IMAGE_NAME}.qcow2"
upload_file_name="${KN_IMAGE_NAME}.${KN_DISC_FORMAT}"

# 1. Possibly download the image
maybe_download_image ${KN_IMAGE_NAME} ${KN_DISC_FORMAT} ${KN_IMAGE_BUCKET_URL}

# 2. Convert image


# 3. Upload image



echo "Image upload done"
