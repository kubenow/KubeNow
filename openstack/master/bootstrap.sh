#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Inititializing the master..."
kubeadm init --token ${kubeadm_token}

echo "Waiting for nodes..."
sleep 120 # We need something smarter here

echo "Deploying wave"
kubectl apply -f https://git.io/weave-kube
