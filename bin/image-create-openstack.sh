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

function get_image_status() {
  local image_name=$1
  local image_id
  local image_details
  image_id=$(get_image_id "${image_name}")
  image_details="$(glance image-show "${image_id}")"

  printf '%s' "${image_details}" |
    grep -w "status" |
    awk -F "|" '{print $3;}' |
    tr -d '[:space:]'
}

function get_image_id() {
  local image_name=$1
  local image_list
  image_list="$(glance image-list)"

  printf '%s' "${image_list}" |
    grep -w "${image_name}" |
    awk -F "|" '{print $2;}' |
    tr -d '[:space:]'
}

function get_server_image_disc_format() {
  local image_id=$1
  local image_details
  image_details="$(glance image-show "${image_id}")"

  printf '%s' "${image_details}" |
    grep -w "disk_format" |
    awk -F "|" '{print $3;}' |
    tr -d '[:space:]'
}

function image_exists() {
  local image_name=$1
  local image_id
  image_id=$(get_image_id "${image_name}")

  if [[ "${image_id}" != "" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

function get_server_uploaded_image_checksum() {
  local image_id=$1
  local image_details
  image_details="$(glance image-show "${image_id}")"

  printf '%s' "${image_details}" |
    grep -w "checksum" |
    awk -F "|" '{print $3;}' |
    tr -d '[:space:]'
}

function is_image_downloaded_already() {
  local download_filepath=$1

  if [[ -e ${download_filepath} ]]; then
    echo "true"
  else
    echo "false"
  fi
}

function is_uploaded_disc_format_as_expected() {
  local image_name=$1
  local glance_disc_format=$2
  local image_id
  image_id=$(get_image_id "${image_name}")
  server_disc_format=$(get_server_image_disc_format "${image_id}")

  if [[ "${server_disc_format}" == "${glance_disc_format}" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

function is_image_already_uploaded() {
  local image_name=$1
  local glance_disc_format=$2
  local image_id
  image_id=$(get_image_id "${image_name}")

  if [[ "${image_id}" == "" ]]; then
    echo "false"
  else
    echo "true"
  fi
}

function wait_for_image_activation() {
  local image_name=$1
  local wait_time
  local max_wait
  local sleep_time
  local status
  wait_time=0
  max_wait=300
  sleep_time=3
  status="nothing"

  # Wait until image status is "active"
  while [[ "${status}" != "active" && ${wait_time} -lt ${max_wait} ]]; do
    # allow for image to be ready
    sleep ${sleep_time}
    wait_time=$((wait_time + sleep_time))
    status=$(get_image_status "${image_name}")
  done

  echo "${status}"
}

function get_host_uploaded_image_checksum() {
  local image_name=$1
  local glance_disc_format=$2
  local image_url=$3
  local upload_filepath="/tmp/${image_name}.${glance_disc_format}"
  local checksum

  if [[ "${glance_disc_format}" == "qcow2" ]]; then
    # Download the checksum of the qcow2 image from Kubenow servers
    curl "${image_url}/${image_name}.md5" \
      -o "${upload_filepath}.md5" \
      --connect-timeout 30 \
      --max-time 30

    checksum=$(cut -f1 -d ' ' "${upload_filepath}.md5")
  else
    # Generate the md5 from the local file which is present on the local disc
    checksum=$(md5sum "${upload_filepath}" | awk '{print $1}')
  fi

  echo "${checksum}"
}

function verify_uploaded_image() {
  local image_name=$1
  local glance_disc_format=$2
  local image_url=$3
  local image_list
  local image_id
  local image_details
  local server_checksum
  local host_checksum
  image_id=$(get_image_id "${image_name}")
  server_checksum=$(get_server_uploaded_image_checksum "${image_id}")

  if [[ ${#server_checksum} != 32 ]]; then
    echo "No valid server_checksum field on server, skipping checksum verification step"
  else
    host_checksum=$(get_host_uploaded_image_checksum "${image_name}" "${glance_disc_format}" "${image_url}")

    if [ "${host_checksum}" != "${server_checksum}" ]; then
      echo >&2 "Server checksum: ${server_checksum}"
      echo >&2 "Expected checksum: ${host_checksum}"
      echo >&2 "The server image checksum does not match expectations"
      echo >&2 "Something might have failed on file transfer."
      echo >&2 "Please delete image ${image_name} from Openstack and try again."
      exit 1
    else
      echo "Uploaded image checksum is OK"
    fi
  fi
}

function upload_image() {
  local image_name=$1
  local glance_disc_format=$2
  local image_url=$3
  local upload_filepath="/tmp/${image_name}.${glance_disc_format}"
  local min_disc=5
  local image_size
  local image_size_number
  image_size=$(du -sh --block-size=G --apparent-size "${upload_filepath}" | awk '{print $1}')
  image_size_number=${image_size::-1}

  if [[ "${glance_disc_format}" == "raw" ]]; then
    min_disc=${image_size_number}
  fi

  # Upload image
  echo "Starting upload of ${image_name}"
  echo ""
  echo "image source: ${upload_filepath}"
  echo "image name: ${image_name}"
  echo "image format: ${glance_disc_format}"
  echo "image size: ${image_size_number} GB"
  echo ""
  glance image-create \
    --file "${upload_filepath}" \
    --disk-format "${glance_disc_format}" \
    --min-disk "${min_disc}" \
    --container-format bare \
    --name "${image_name}" \
    --progress

  # Wait until image status is "active"
  wait_for_image_activation "$image_name"

  echo "Verifying the uploaded image"
  echo ""

  post_image_upload_checks "${image_name}" "${glance_disc_format}" "${image_url}"
}

function verify_downloaded_image() {
  local download_filename=$1
  local download_url=$2
  local download_filepath="/tmp/${download_filename}"

  echo "Downloading ${download_url}/${download_filename}.md5 file"
  curl "${download_url}/${download_filename}.md5" \
    -o "${download_filepath}.md5" \
    --connect-timeout 30 \
    --max-time 30

  # Verify md5sum of downloaded file
  echo "Checking md5 sum"
  md5result=$(
    cd /tmp || exit
    md5sum -c "${download_filename}.md5"
  )
  if [[ "${md5result}" != *": OK"* ]]; then
    echo >&2 "Wrong checksum of downloaded image."
    echo >&2 "Something might have failed on file transfer."
    echo >&2 "Please try again."
    exit 1
  else
    echo "Checksum of downloaded image OK"
  fi
}

function post_image_upload_checks() {
  local image_name=$1
  local glance_disc_format=$2
  local image_url=$3
  local is_uploaded_disc_format_as_expected
  local image_id
  image_id=$(get_image_id "${image_name}")
  server_image_disc_format=$(get_server_image_disc_format "${image_id}")
  is_uploaded_disc_format_as_expected=$(is_uploaded_disc_format_as_expected "${image_name}" "${glance_disc_format}")

  # Verify the server image is in the expected glance_disc_format
  if [[ "${is_uploaded_disc_format_as_expected}" == "false" ]]; then
    echo >&2 "Host image disc format: ${glance_disc_format}"
    echo >&2 "Server image disc format: ${server_image_disc_format}"
    echo >&2 "${image_name} disc format on the server is not as expected"
    echo >&2 "Delete the server image and retry the kn init process"
    exit 1
  fi

  # Verify uploaded image checksums
  verify_uploaded_image "${image_name}" "${glance_disc_format}" "${image_url}"
}

function download_image() {
  local download_filename=$1
  local download_url=$2
  local download_filepath="/tmp/${download_filename}"

  echo "Downloading image to local /tmp/"
  echo ""
  curl "${download_url}/${download_filename}" \
    -o "${download_filepath}" \
    --connect-timeout 30 \
    --max-time 1800

  echo "Verifying the md5 checksum of the downloaded image"
  echo ""
  verify_downloaded_image "${download_filename}" "${download_url}"
}

function maybe_download_image() {
  local image_name=$1
  local glance_disc_format=$2
  local download_url=$3
  local download_filename="${image_name}.qcow2"
  local download_filepath="/tmp/${image_name}.qcow2"
  local is_image_downloaded_already
  is_image_downloaded_already=$(is_image_downloaded_already "${download_filepath}")

  if [[ "${is_image_downloaded_already}" == "false" ]]; then
    download_image "${download_filename}" "${download_url}"
  else
    echo "${download_filename} is already downloaded"
    echo "Verifying the downloaded image checksum"
    echo ""

    verify_downloaded_image "${download_filename}" "${download_url}"
  fi
}

function maybe_convert_image() {
  local image_name=$1
  local glance_disc_format=$2
  local download_url=$3
  local download_filename="${image_name}.qcow2"
  local download_filepath="/tmp/${image_name}.qcow2"
  local upload_filepath="/tmp/${image_name}.${glance_disc_format}"
  local is_image_downloaded_already
  is_image_downloaded_already=$(is_image_downloaded_already "${download_filepath}")

  if [[ ! -e ${upload_filepath} ]]; then
    if [[ "${is_image_downloaded_already}" == "false" ]]; then
      echo >&2 "No file found at ${download_filepath}"
      echo >&2 "Please ensure image has been downloaded"
      exit 1
    fi

    echo "${download_filepath} has not yet been converted to the ${glance_disc_format} format"
    echo "Starting the image conversion from qcow2 to ${glance_disc_format}..."
    echo ""

    qemu-img convert -q -f qcow2 -O "${glance_disc_format}" "${download_filepath}" "${upload_filepath}"

    echo "${image_name}.qcow2 conversion to ${upload_filepath} complete"
  else
    echo "${upload_filepath} already exists and so does not require conversion"
  fi
}

function main() {
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

# Default bucket URL
KN_IMAGE_BUCKET_URL=${KN_IMAGE_BUCKET_URL:-"https://s3.eu-central-1.amazonaws.com/kubenow-eu-central-1"}

echo "Started script image-create-openstack"

if [ -z "${KN_IMAGE_NAME}" ]; then
  echo >&2 "env KN_IMAGE_NAME must be set for this script to run"
  exit 1
fi

if [ -z "${KN_GLANCE_DISC_FORMAT}" ]; then
  echo >&2 "env KN_GLANCE_DISC_FORMAT must be set for this script to run"
  exit 1
fi

main "${KN_IMAGE_NAME}" "${KN_GLANCE_DISC_FORMAT}" "${KN_IMAGE_BUCKET_URL}"

echo "Finished script image-create-openstack"
