#!/usr/bin/env bash

# Checks and uploads specified Image to user's Google account.
# Uses google command line client to do the job.
#
# Env vars
#   KN_IMAGE_NAME
#   KN_GCE_ACCOUNT_FILE_PATH

# Exit immediately if a command exits with a non-zero status
set -e

echo "Started script image-create-gce"

if [ -z "$KN_IMAGE_NAME" ]; then
  echo >&2 "env KN_IMAGE_NAME must be set for this script to run"
  exit 1
fi

if [ -z "$KN_GCE_ACCOUNT_FILE_PATH" ]; then
  echo >&2 "env KN_GCE_ACCOUNT_FILE_PATH must be set for this script to run"
  exit 1
fi

echo "Login"
gcloud auth activate-service-account --key-file="$KN_GCE_ACCOUNT_FILE_PATH"

# Get project_id from json formatted account file
project_id=$(jq -r .project_id <"$KN_GCE_ACCOUNT_FILE_PATH")
gcloud config set project "$project_id"

echo "Check if image exists already"
image_status="$(gcloud compute images list)"
existing_image=$(echo "$image_status" | grep "\b$KN_IMAGE_NAME\s" || true)
if [ -z "$existing_image" ]; then

  echo "Image does not exist in this account"

  # Run exec in background and capture stdout of the job as (input) fd 3.
  exec 3< <(gcloud compute images create "$KN_IMAGE_NAME" \
    --source-uri "gs://kubenow-images/$KN_IMAGE_NAME.tar.gz" 2>&1)

  # Process Id of the previous running command
  pid=$!

  # This loop is running while process id of previous image create
  # command running in background still is alive and creating image
  # While running it is updating the status message with the time
  # that has elapsed and also continously changing the spinner character
  # It uses bash builtin SECONDS to display running time to user
  SECONDS=0
  spin_char='-\|/'
  while kill -0 $pid 2>/dev/null; do
    sec=$((SECONDS % 60))
    min=$((SECONDS/60 % 60))
    hrs=$((SECONDS/60/60))
    i=$(((i + 1) % 4))
    printf "\r%s Creating image (usually takes 3-10min) time elapsed: %d:%02d:%02d" \
      "${spin_char:$i:1}" "$hrs" "$min" "$sec"
    sleep .3
  done

  # print output from background job
  result=$(cat <&3)
  printf "\n%s\n" "$result"

else
  echo "Image exists - no need to create"
fi
