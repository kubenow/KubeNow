#!/usr/bin/env bash

function is_image_downloaded_already() {
  local download_filename=$1;

  if [[ -e ${download_filename} ]]; then
    echo "true"
  else
    echo "false"
  fi
}

function is_image_already_uploaded() {
  local image_name=$1;
  local disc_format=$2;
  local uploaded_image_name="${image_name}.${disc_format}"

  # Check if image is present already
  echo "List images available in OpenStack..."
  image_list="$(glance image-list)"
  image_id="$(printf '%s' "${image_list}" |
    grep "\s${uploaded_image_name}\s" |
    awk -F "|" '{print $2;}' |
    tr -d '[:space:]')"

  # If it exists, return true, otherwise return false
  if [ -n "${image_id}" ]; then
    echo "true"
  else
    echo "false"
  fi
}

function verify_uploaded_image() {
  local image_name=$1;
  local disc_format=$2;
  local image_url=$3;
  local upload_filename="${image_name}.${disc_format}"

  # Get checksum of uploaded file
  image_details="$(glance image-show "${image_id}")"
  checksum="$(printf '%s' "${image_details}" |
    grep -w "checksum" |
    awk -F "|" '{print $3;}' |
    tr -d '[:space:]')"

  # Get checksum of bucket image
  echo "Download md5 sum file"
  curl "${image_url}/${upload_filename}.md5" \
    -o "/tmp/${upload_filename}.md5" \
    --connect-timeout 30 \
    --max-time 30

  md5only=$(cut -f1 -d ' ' "/tmp/${upload_filename}.md5")
  if [ "${md5only}" != "${checksum}" ]; then
    echo >&2 "Wrong checksum of present/uploaded image."
    echo >&2 "Something might have failed on file transfer."
    echo >&2 "Please delete image ${image_name} from Openstack and try again."
    exit 1
  else
    echo "Checksum OK"
  fi
}

function upload_image() {
  local image_name=$1
  local disc_format=$2
  local image_url=$3
  local upload_filename="${image_name}.${disc_format}"
  local min_disc=20

  if [[ "${disc_format}" == "raw" ]]; then
    min_disc=25;
  fi

  # Upload image
  echo "Uploading image"
  glance image-create \
    --file "/tmp/${upload_filename}" \
    --disk-format ${disc_format} \
    --min-disk ${min_disc} \
    --container-format bare \
    --name "${image_name}" \
    --progress

  echo "Verify md5 of present/uploaded image..."
  echo "List images available in OpenStack..."
  image_list="$(glance image-list)"
  image_id="$(printf '%s' "${image_list}" |
    grep "\s${image_name}\s" |
    awk -F "|" '{print $2;}' |
    tr -d '[:space:]')"

  verify_uploaded_image ${image_name} ${disc_format} ${image_url}
}

function verify_downloaded_image() {
  local filename=$1
  local download_url=$2

  echo "Download md5 sum file"
  curl "${download_url}/$filename.md5" \
    -o "/tmp/$filename.md5" \
    --connect-timeout 30 \
    --max-time 1800

  # Verify md5sum of downloaded file
  echo "Check md5 sum"
  md5result=$(
    cd /tmp
    md5sum -c "$filename.md5"
  )
  if [[ "$md5result" != *": OK"* ]]; then
    echo >&2 "Wrong checksum of downloaded image."
    echo >&2 "Something might have failed on file transfer."
    echo >&2 "Please try again."
    exit 1
  else
    echo "Checksum of downloaded image OK"
  fi
}

function download_image() {
  local filename=$1
  local download_url=$2

  echo "Downloading image to local /tmp/"
  curl "${download_url}/$filename" \
    -o "/tmp/${filename}" \
    --connect-timeout 30 \
    --max-time 1800

  verify_downloaded_image ${filename} ${download_url}
}

function maybe_download_image(){
  local image_name=$1
  local disc_format=$2
  local download_url=$3
  local download_filename="${image_name}.qcow2"

  if [[ "$(is_image_downloaded_already ${download_filename})" == "false" ]]; then
    download_image ${download_filename} ${download_url}
  else
    echo "${download_filename} is already downloaded"

    verify_downloaded_image ${download_filename} ${download_url}
  fi
}

function maybe_convert_image(){
  local image_name=$1
  local disc_format=$2
  local download_filename="${image_name}.qcow2"
  local upload_filename="${image_name}.${disc_format}"

  if [[ ! `which qmeu` == "" ]]; then
    echo "qemu-utils package is missing - image cannot be converted"
  else
    if [[ ! -e ${upload_filename} ]]; then
      qemu-img convert -q -f qcow2 -O ${disc_format} ${download_filename} ${upload_filename}
    fi
  fi
}

function maybe_upload_image() {
  local image_name=$1
  local disc_format=$2
  local image_url=$3
  local upload_filename="${image_name}.${disc_format}"

  if [[ "$(is_image_already_uploaded {image_name} ${disc_format})" == "false" ]]; then
    maybe_convert_image ${image_name} ${disc_format}
    upload_image ${image_name} ${disc_format} ${image_url}
  else
    echo "${upload_filename} is already uploaded"
  fi
}