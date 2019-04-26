#!/bin/bash

set -e

# Add hostname
echo "127.0.0.1 $HOSTNAME" >>/etc/hosts

# Rancher prerequisites
# see: https://rancher.com/docs/rke/latest/en/os/
curl "releases.rancher.com/install-docker/17.03.sh" | bash
# User need to be in docker group
sudo usermod -aG docker ubuntu

# Extra requirements
sudo apt-get -qq install -y nfs-common

echo "Bootstrap finished"
