#!/bin/bash

# Add hostname
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

# Taint and label
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

# execute modprobe on node - workaround for heketi gluster
echo "Modprobe dm_thin_pool..."
modprobe dm_thin_pool

echo "Inititializing the master...."

if [ -n "$API_ADVERTISE_ADDRESSES" ]
then
    # shellcheck disable=SC2154
    kubeadm init --token "${kubeadm_token}" --kubernetes-version=v1.6.4 --api-advertise-address="$API_ADVERTISE_ADDRESSES"
else
    # shellcheck disable=SC2154
    kubeadm init --token "${kubeadm_token}" --kubernetes-version=v1.6.4
fi

# Copy kubernetes configuration created by kubeadm (admin.conf to .kube/config)
# shellcheck disable=SC2154
SSH_USER="${ssh_user}"
mkdir -p "/home/$SSH_USER/.kube/"
chown "$SSH_USER":"$SSH_USER" "/home/$SSH_USER/.kube/"
cp "/etc/kubernetes/admin.conf" "/home/$SSH_USER/.kube/config"
chown "$SSH_USER":"$SSH_USER" "/home/$SSH_USER/.kube/config"

