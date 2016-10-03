#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Inititializing the master..."
sudo kubeadm init --token ${kubeadm_token}
