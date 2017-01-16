#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Ensure that APT works with HTTPS..."
sudo apt-get update -y
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  software-properties-common \
  curl

echo "Add Kubernetes repo..."
sudo sh -c 'curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -'
sudo sh -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'

echo "Add Docker repo..."
sudo apt-key adv \
  --keyserver hkp://p80.pool.sks-keyservers.net:80 \
  --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo sh -c 'echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list'

echo "Add GlusterFS repo..."
sudo add-apt-repository -y ppa:gluster/glusterfs-3.9

echo "Updating Ubuntu..."
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

echo "Installing Kubernetes requirements..."
sudo apt-get install -y \
  linux-image-extra-$(uname -r) \
  linux-image-extra-virtual \
  docker-engine=1.12.5-0~ubuntu-xenial \
  kubelet=1.5.1-00 \
  kubeadm=1.6.0-alpha.0-2074-a092d8e0f95f52-00 \
  kubectl=1.5.1-00 \
  kubernetes-cni=0.3.0.1-07a8a2-00

echo "Installing other requirements..."
# APT requirements
sudo apt-get install -y \
  python \
  daemon \
  attr \
  glusterfs-client \
  jq

# Helm
HELM_TGZ=helm-v2.1.0-linux-amd64.tar.gz
wget -P /tmp/ https://kubernetes-helm.storage.googleapis.com/$HELM_TGZ
tar -xf /tmp/$HELM_TGZ -C /tmp/
sudo mv /tmp/linux-amd64/helm /usr/local/bin/

echo "Pulling required Docker images..."
sudo docker pull \
  kubenow/gluster-server:0.1.0
