#!/bin/bash

# Add labels to node key=value pairs separated by ','
echo "Label nodes"
echo "Label and taint nodes"
sed -i 's|KUBELET_KUBECONFIG_ARGS=|KUBELET_KUBECONFIG_ARGS=--node-labels=${node_labels} |g' \
       /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# reload and restart after systemd dropin edits
systemctl daemon-reload
systemctl restart kubelet

echo "Inititializing the master..."

if [ -n "$api_advertise_addresses" ]
then
    kubeadm init --token ${kubeadm_token} --kubernetes-version=v1.5.2 --api-advertise-addresses=$api_advertise_addresses
else
    kubeadm init --token ${kubeadm_token} --kubernetes-version=v1.5.2
fi
