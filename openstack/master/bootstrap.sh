#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Inititializing the master..."
kubeadm init --token ${kubeadm_token}

echo "Waiting for nodes..."
while [ $(kubectl get nodes | grep Ready | wc -l) \
  -lt $((${node_count} + 1)) ]; do
  sleep 20
  echo "... waiting for nodes ..."
done

echo "Deploying wave"
kubectl apply -f https://git.io/weave-kube
