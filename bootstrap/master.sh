#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

export KUBE_LOGGING_DESTINATION=elasticsearch;
export KUBE_ENABLE_NODE_LOGGING=true;

echo "Inititializing the master..."
kubeadm init --token ${kubeadm_token}
