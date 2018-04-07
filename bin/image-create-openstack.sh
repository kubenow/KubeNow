#!/usr/bin/env bash

# Checks and uploads specified Image to user's OpenStack account.
#
# 1. Downloads image first from an Amazon S3 storage (using curl and python-glance client)
#
# 2. Converts the image to the required format (if needed)
#
# 3. Uploads image to openstack tenancy. (using curl and python-glance client)
#
#
#
# Env vars
#
#   KN_IMAGE_NAME
#   KN_DISC_FORMAT
#   KN_IMAGE_BUCKET_URL
#
# Exit immediately if a command exits with a non-zero status

set -e

source ./bin/openstack/functions.sh
KN_IMAGE_BUCKET_URL=${KN_IMAGE_BUCKET_URL:-"https://s3.eu-central-1.amazonaws.com/kubenow-eu-central-1"}

echo "Started script image-create-openstack"

if [ -z "${KN_IMAGE_NAME}" ]; then
  echo >&2 "env KN_IMAGE_NAME must be set for this script to run"
  exit 1
fi

if [ -z "${KN_DISC_FORMAT}" ]; then
  echo >&2 "env KN_DISC_FORMAT must be set for this script to run"
  exit 1
fi

maybe_download_image ${KN_IMAGE_NAME} ${KN_DISC_FORMAT} ${KN_IMAGE_BUCKET_URL}
maybe_convert_image ${KN_IMAGE_NAME} ${KN_DISC_FORMAT}
maybe_upload_image ${KN_IMAGE_NAME} ${KN_DISC_FORMAT} ${KN_IMAGE_BUCKET_URL}
