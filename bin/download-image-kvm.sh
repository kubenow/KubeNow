#!/bin/bash

# Download cloud image if not there already
IMAGE_FILE="xenial-server-cloudimg-amd64-disk1.img"
IMAGE_REPO="https://cloud-images.ubuntu.com/xenial/current"
if [[ ! -f "/tmp/kvm-image/$IMAGE_FILE" ]]; then
  mkdir -p /tmp/kvm-image/
  wget "$IMAGE_REPO/$IMAGE_FILE" -P /tmp/kvm-image/
fi
# Copy and resize image
cp /tmp/kvm-image/ . -r
qemu-img resize "kvm-image/$IMAGE_FILE" +100G
# generate new md5sum after resize
md5sum "kvm-image/$IMAGE_FILE" > "kvm-image/$IMAGE_FILE.md5"

