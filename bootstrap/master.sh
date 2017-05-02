#!/bin/bash

node_labels=${node_labels}
node_taints=${node_taints}

echo "Label nodes"
if [ -n "$node_labels" ]
then
    sed -i "s|KUBELET_KUBECONFIG_ARGS=|KUBELET_KUBECONFIG_ARGS=--node-labels=$node_labels |g" \
       /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi
   
echo "Taint nodes"    
if [ -n "$node_taints" ]
then
    sed -i "s|KUBELET_KUBECONFIG_ARGS=|KUBELET_KUBECONFIG_ARGS=--register-with-taints=$node_taints |g" \
       /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi

# reload and restart after systemd dropin edits
systemctl daemon-reload
systemctl restart kubelet

echo "Inititializing the master..."

if [ -n "$api_advertise_addresses" ]
then
    kubeadm init --token ${kubeadm_token} --use-kubernetes-version=v1.5.2 --api-advertise-address=$api_advertise_addresses
else
    kubeadm init --token ${kubeadm_token} --use-kubernetes-version=v1.5.2
fi

