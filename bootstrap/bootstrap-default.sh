#!/bin/bash

# Add hostname
echo "127.0.0.1 $HOSTNAME" >>/etc/hosts

# Make sure instance is updated with latest security fixes
# Run upgrades in a subshell that always succeeds so boot is not interrupted
#echo "Run unattended-upgrade in subshell"
#sudo bash -c 'apt-get update -y && unattended-upgrade -d'

# Taint and label
node_labels="${node_labels}"
node_taints="${node_taints}"

echo "Label nodes"
if [ -n "$node_labels" ]; then
  sed -i "s|KUBELET_KUBECONFIG_ARGS=|KUBELET_KUBECONFIG_ARGS=--node-labels=$node_labels |g" \
    /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi

echo "Taint nodes"
if [ -n "$node_taints" ]; then
  sed -i "s|KUBELET_KUBECONFIG_ARGS=|KUBELET_KUBECONFIG_ARGS=--register-with-taints=$node_taints |g" \
    /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
fi

echo "Add cloud-config file"
cat > /etc/kubernetes/cloud-config <<EOL
[Global]
auth-url=" - some auth url param e.g. https://uppmax.cloud.snic.se:5000/v3"
tenant-id=" - same as project id - e.g. 9301f656901b45c291887b5012f44a20" 
username=" - your user id, e.g. s6215" 
password=" - user password"  
EOL

echo "Add cloud-config flag"
sed -i "s|KUBELET_KUBECONFIG_ARGS=|KUBELET_KUBECONFIG_ARGS=--cloud-provider=openstack --cloud-provider=openstack --cloud-config=/etc/kubernetes/cloud-config |g" \
  /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# reload and restart after systemd dropin edits
systemctl daemon-reload
systemctl restart kubelet

# execute modprobe on node - workaround for heketi gluster
echo "Modprobe dm_thin_pool..."
modprobe dm_thin_pool

# make sure swap is off
sudo swapoff -a
# make sure any line with swap is removed from fstab
sudo sed -i '/swap/d' /etc/fstab

# Execute kubeadm init vs. kubeadm join depending on node type
if [[ "$node_labels" == *"role=master"* ]]; then
  echo "Inititializing the master...."

  echo "Create kubeadm conf-file"
  echo "kind: MasterConfiguration" > /etc/kubernetes/kubeadm-extra.config
  echo "apiVersion: kubeadm.k8s.io/v1alpha1" >> /etc/kubernetes/kubeadm-extra.config
  echo "kubernetesVersion: v1.9.2" >> /etc/kubernetes/kubeadm-extra.config
  # I did not get this bootstrap tokens in this config to work Instead create below
  echo "bootstrapTokens:" >> /etc/kubernetes/kubeadm-extra.config
  echo "- groups:" >> /etc/kubernetes/kubeadm-extra.config
  echo "  - system:bootstrappers:kubeadm:default-node-token" >> /etc/kubernetes/kubeadm-extra.config
  echo "  token: \"${kubeadm_token}\"" >> /etc/kubernetes/kubeadm-extra.config
  echo "  ttl: 0" >> /etc/kubernetes/kubeadm-extra.config
  echo "  usages:" >> /etc/kubernetes/kubeadm-extra.config
  echo "  - signing" >> /etc/kubernetes/kubeadm-extra.config
  echo "  - authentication" >> /etc/kubernetes/kubeadm-extra.config
  echo "networking:" >> /etc/kubernetes/kubeadm-extra.config
  echo "  podSubnet: 10.244.0.0/16" >> /etc/kubernetes/kubeadm-extra.config
  echo "cloudProvider: openstack" >> /etc/kubernetes/kubeadm-extra.config
  
  if [ -n "$API_ADVERTISE_ADDRESSES" ]; then
    echo "api:" >> /etc/kubernetes/kubeadm-extra.config
    echo "  advertiseAddress: $API_ADVERTISE_ADDRESSES" >> /etc/kubernetes/kubeadm-extra.config
  fi
  
  # Init cluster (master)
  kubeadm init --config "/etc/kubernetes/kubeadm-extra.config"
  # create token (has to be done after init - otherwise kubeadm config files are missing)
  # shellcheck disable=SC2154
  kubeadm token create --ttl 0 "${kubeadm_token}"

  # Copy Kubernetes configuration created by kubeadm (admin.conf to .kube/config)
  # shellcheck disable=SC2154
  SSH_USER="${ssh_user}"
  mkdir -p "/home/$SSH_USER/.kube/"
  chown "$SSH_USER":"$SSH_USER" "/home/$SSH_USER/.kube/"
  cp "/etc/kubernetes/admin.conf" "/home/$SSH_USER/.kube/config"
  chown "$SSH_USER":"$SSH_USER" "/home/$SSH_USER/.kube/config"
else
  echo "Try to join master..."
  # shellcheck disable=SC2154
  kubeadm join --discovery-token-unsafe-skip-ca-verification --token "${kubeadm_token}" "${master_ip}:6443"
fi
