#!/bin/bash

echo "Inititializing the master..."

if [ -n "$api_advertise_addresses" ]
then
    kubeadm init --token ${kubeadm_token} --api-advertise-addresses=$api_advertise_addresses
else
    kubeadm init --token ${kubeadm_token}
fi
