#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Ensure that APT works with HTTPS..."
sudo apt-get update
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates

echo "Add Kubernetes repo..."
sudo sh -c 'curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -'
sudo sh -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'

echo "Add Docker repo..."
sudo apt-key adv \
  --keyserver hkp://p80.pool.sks-keyservers.net:80 \
  --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo sh -c 'echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list'

echo "Updating Ubuntu..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installing Kubernetes requirements..."
sudo apt-get install -y \
  linux-image-extra-$(uname -r) \
  linux-image-extra-virtual \
  docker-engine \
  kubelet \
  kubeadm \
  kubectl \
  kubernetes-cni

echo "Installing other requirements..."
# APT requirements
sudo apt-get install -y \
  python \
  daemon \
  attr \
  glusterfs-client

# Helm
HELM_TGZ=helm-v2.0.0-linux-amd64.tar.gz
wget -P /tmp/ https://kubernetes-helm.storage.googleapis.com/$HELM_TGZ
tar -xf /tmp/$HELM_TGZ -C /tmp/
sudo mv /tmp/linux-amd64/helm /usr/local/bin/

echo "Pulling required Docker images..."
sudo docker pull \
  kubenow/gluster-server
