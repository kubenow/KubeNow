#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Inititializing the master..."
kubeadm init --token ${kubeadm_token}
