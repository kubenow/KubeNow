#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Add Kubernetes repo..."
sudo sh -c 'curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -'
sudo sh -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'

echo "Updating Ubuntu..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installing Kubernetes requirements..."
sudo apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni

echo "Installing Python..."
sudo apt-get install -y python
