#!/bin/bash

# Add labels to node key=value pairs separated by ','
echo "Label nodes"
sed -i 's|KUBELET_KUBECONFIG_ARGS=|KUBELET_KUBECONFIG_ARGS=--node-labels=${node_labels} |g' \
       /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
   
echo "Taint nodes"    
if [ -n "$node_taints" ]
then
    sed -i 's|KUBELET_KUBECONFIG_ARGS=|KUBELET_KUBECONFIG_ARGS=--register-with-taints=${node_taints} |g' \
       /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi

# reload and restart after systemd dropin edits
systemctl daemon-reload
systemctl restart kubelet

echo "Inititializing the master..."

if [ -n "$api_advertise_addresses" ]
then
    kubeadm init --token ${kubeadm_token} --kubernetes-version=v1.6.1 --apiserver-advertise-address=$api_advertise_addresses
else
    kubeadm init --token ${kubeadm_token} --kubernetes-version=v1.6.1
fi

echo "Copy admin.conf to .kube/config"
USER=ubuntu
mkdir -p "/home/$USER/.kube/"
chown $USER:$USER "/home/$USER/.kube/"
cp "/etc/kubernetes/admin.conf" "/home/$USER/.kube/config"
chown $USER:$USER "/home/$USER/.kube/config"
