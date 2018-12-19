#!/bin/bash

set -e

# Add hostname
echo "127.0.0.1 $HOSTNAME" >>/etc/hosts

#echo "Ensure that APT works with HTTPS..."
#sudo apt-get -qq update -y
#sudo apt-get -qq install -y \
#  apt-transport-https \
#  ca-certificates \
#  software-properties-common \
#  curl
#echo "Add Docker repo..."
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

#echo "Updating Ubuntu..."
#sudo apt-get -qq update -y
#sudo DEBIAN_FRONTEND=noninteractive \
#  apt-get -y -qq \
#  -o Dpkg::Options::="--force-confdef" \
#  -o Dpkg::Options::="--force-confold" \
#  upgrade

#echo "Installing Kubernetes requirements..."
#sudo apt-get -qq install -y \
#  docker-ce=17.03.3~ce-0~ubuntu-xenial

curl "releases.rancher.com/install-docker/17.03.sh" | bash
sudo usermod -aG docker ubuntu

echo "Bootstrap finished OK"
