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

echo "Try to join master..."
kubeadm join --token ${kubeadm_token} "${master_ip}"

