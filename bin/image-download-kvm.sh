#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

IMG_VERSION=${KN_IMG_VERSION:="v031-26-g8b8c758-test"}
IMAGE_NAME=${KN_IMAGE_NAME:="kubenow-$IMG_VERSION"}
FILE_NAME=${KN_FILE_NAME:="$IMAGE_NAME.qcow2"}
IMAGE_BUCKET_URL=${KN_IMAGE_BUCKET_URL:="https://s3.eu-central-1.amazonaws.com/kubenow-eu-central-1"}
LOCAL_DIR=${KN_LOCAL_DIR:="$HOME/.kubenow"}

# check if image is present locally already (then also verify md5 sum)
if [ -e "$LOCAL_DIR/$FILE_NAME" ] && [ -e "$LOCAL_DIR/$FILE_NAME.md5" ]; then
  echo "Check md5 sum"
  md5only=$( cut -f1 -d ' ' "$LOCAL_DIR/$FILE_NAME.md5")
  if md5sum -c <<< "$md5only  $LOCAL_DIR/$FILE_NAME"; then
    echo "File exists, checksum is OK. Exit"
    exit 0
  else
    echo "File exists, checksum is wrong, continuing..."
  fi
fi

# Make sure file exists on server
response=$(curl "$IMAGE_BUCKET_URL/$FILE_NAME" \
             --connect-timeout 30 \
             --max-time 1800 \
             --head \
             --write-out "%{http_code}" \
             --silent \
             --output /dev/null)

if [[ "$response" != 200 ]]; then
  if [[ "$response" == 404 ]]; then
    echo "Error from download server: File not found: $IMAGE_BUCKET_URL/$FILE_NAME";
    exit 1;
  else
    echo "Error code from download server: $IMAGE_BUCKET_URL/$FILE_NAME";
    exit 1;
  fi
fi

echo "Downloading image to local dir $LOCAL_DIR"

mkdir -p "$LOCAL_DIR"
curl "$IMAGE_BUCKET_URL/$FILE_NAME" \
     -o "$LOCAL_DIR/$FILE_NAME" \
     --connect-timeout 30 \
     --max-time 1800

echo "Download md5 sum file"
curl "$IMAGE_BUCKET_URL/$FILE_NAME.md5" \
     -o "$LOCAL_DIR/$FILE_NAME.md5" \
     --connect-timeout 30 \
     --max-time 1800

echo "Check md5 sum"
md5only=$( cut -f1 -d ' ' "$LOCAL_DIR/$FILE_NAME.md5")
if md5sum -c <<< "$md5only  $LOCAL_DIR/$FILE_NAME"; then
  echo "Checksum is OK"
else
  echo "Checksum is wrong. Downloading image has failed - please try running again. Exit"
  exit 1
fi

echo "Cleaning up old KuneNow images in local folder"
# find and rm all images (and md5 files) but not current one
find "$LOCAL_DIR" -name 'kubenow-*.qcow*' ! -name "$FILE_NAME*" -exec rm {} \;

