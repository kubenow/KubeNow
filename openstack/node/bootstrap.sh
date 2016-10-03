#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Sleep 60 seconds..." #Give the master some time to start
sleep 60 # We need something smarter here

echo "Joining the master..."
kubeadm join --token ${kubeadm_token} ${master_ip}
