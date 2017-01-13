#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# set -e

echo "Inititializing the master..."

if [ -n "$api_advertise_addresses" ]
then
    kubeadm init --token ${kubeadm_token} --api-advertise-addresses=${api_advertise_addresses}
else
    kubeadm init --token ${kubeadm_token}
fi

