#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

GCE_ACCOUNT_FILE_PATH=${GCE_ACCOUNT_FILE_PATH:-1}
if [ -z "$GCE_ACCOUNT_FILE_PATH" ]; then
  echo "env GCE_ACCOUNT_FILE_PATH must set or be the first argument for this script"
  exit 1
fi

IMG_VERSION=${IMG_VERSION:-"v040b1"}
IMAGE_NAME="kubenow-$IMG_VERSION"

echo "Login"
gcloud auth activate-service-account --key-file="$GCE_ACCOUNT_FILE_PATH"

echo "Set project"
project_id="$(cat service-account.json | jq -r .project_id)"
gcloud config set project "$project_id"

echo "Check if image exists already"
image_status="$(gcloud compute images list)"
image_name=$(echo "$image_status" | grep  "\b$IMAGE_NAME\s" || true)
if [ -z "$image_name" ]; then

  SECONDS=0

  # exec in background and capture stdout of the job as (input) fd 3.
  exec 3< <(gcloud compute images create "$IMAGE_NAME" \
                                  --source-uri "gs://kubenow-images/$IMAGE_NAME.tar.gz" 2>&1)

  # Process Id of the previous running command
  pid=$!

  # Spinner while $pid is alive and running
  spin='-\|/'
  while kill -0 $pid 2>/dev/null
  do
    sec=$((SECONDS%60))
    min=$((SECONDS/60%60))
    hrs=$((SECONDS/60/60))
    i=$(( (i+1) %4 ))
    printf "\r%s Creating image (usually takes 3-10min) time elapsed: %d:%02d:%02d" "${spin:$i:1}" "$hrs" "$min" "$sec"
    sleep .3
  done

  # print output from background job
  result=$(cat <&3)
  printf "\n%s\n" "$result"

else
  echo "Image exists - no need to create"
fi


