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

# shellcheck disable=SC1091
source bin/helpers/openstack.sh
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

function init() {
  local image_name=$1
  local glance_disc_format=$2
  local bucket_url=$3
  local is_image_previously_uploaded

  # If the image exists, return true, otherwise return false
  is_image_previously_uploaded=$(is_image_already_uploaded "${image_name}" "${glance_disc_format}")
  if [[ "${is_image_previously_uploaded}" == "false" ]]; then
    maybe_download_image "${image_name}" "${glance_disc_format}" "${bucket_url}"
    maybe_convert_image "${image_name}" "${glance_disc_format}" "${bucket_url}"
    upload_image "${image_name}" "${glance_disc_format}" "${bucket_url}"
  else
    echo "${image_name}.${glance_disc_format} is already present - no need to upload"
  fi
}

init "${KN_IMAGE_NAME}" "${KN_DISC_FORMAT}" "${KN_IMAGE_BUCKET_URL}"



