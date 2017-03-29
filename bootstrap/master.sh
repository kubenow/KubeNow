#!/bin/bash

echo "Inititializing the master..."

if [ -n "$api_advertise_addresses" ]
then
    kubeadm init --token ${kubeadm_token} --use-kubernetes-version=v1.5.2 --api-advertise-addresses=$api_advertise_addresses
else
    kubeadm init --token ${kubeadm_token} --use-kubernetes-version=v1.5.2
fi
