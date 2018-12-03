#!/bin/bash

# Add hostname
echo "127.0.0.1 $HOSTNAME" >>/etc/hosts

if [[ "${use_external_net}" == "1" || $(echo ${use_external_net} | tr '[:upper:]' '[:lower:]') == "true" ]]; then
  # Collect name of network interfaces
  interfaces=$(cat /proc/net/dev | grep ens | cut -d':' -f1)
  # Detect primary interface
  primary_interface=$(ifconfig | grep -m1 ens | awk '{print $1}')
  echo "Primary interface: $i"
  # Detect secondary interface
  for i in $interfaces; do 
    if [[ "$i" != "$primary_interface"  ]]; then 
      echo "Secondary interface: $i"
      secondary_interface="$i"
      break
    fi
  done

  # Check if network interfaces have been detected
  if [[ -z "$primary_interface" || -z "$secondary_interface" ]]; then
    echo "Couldn't retrieve network interfaces" >&2
    echo "Primary interface: $primary_interface; Public gateway: $secondary_interface" >&2
    exit 1
  fi

  # Add external interface
  echo -e "auto $secondary_interface\niface $secondary_interface inet dhcp" > /etc/network/interfaces.d/ext-net.cfg
  service networking restart

  # Detect gateways
  private_net_gateway=$(tac "/var/lib/dhcp/dhclient.$primary_interface.leases" | grep -m1 'option routers' | awk '{print $3}' | sed -e 's/;//')
  public_net_gateway=$(tac "/var/lib/dhcp/dhclient.$secondary_interface.leases" | grep -m1 'option routers' | awk '{print $3}' | sed -e 's/;//')

  if [[ -z "$private_net_gateway" || -z "$public_net_gateway" ]]; then 
    echo "Couldn't retrieve gateway routers" >&2
    echo "Private gateway: $private_net_gateway; Public gateway: $public_net_gateway" >&2
    exit 1
  fi

  # Update routes
  route add default gw $public_net_gateway $secondary_interface
  route del default gw $private_net_gateway $primary_interface

  # Primary interface info
  network_1_addr=$(ip -o -4 a | awk "/\<$primary_interface\>/{print \$4}") 
  network_1_ip=$(cut -d'/' -f1 <<<"$network_1_addr")
  network_1_cl=$(cut -d'/' -f2 <<<"$network_1_addr")

  # Set advertise address of Kubernetes Master
  API_ADVERTISE_ADDRESSES="$network_1_ip"
fi

# Taint and label
node_labels=${node_labels}
node_taints=${node_taints}

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

# reload and restart after systemd dropin edits
systemctl daemon-reload
systemctl restart kubelet

# execute modprobe on node - workaround for heketi gluster
echo "Modprobe dm_thin_pool..."
modprobe dm_thin_pool
modprobe dm_multipath

# make sure swap is off
sudo swapoff -a
# make sure any line with swap is removed from fstab
sudo sed -i '/swap/d' /etc/fstab

echo "Inititializing the master...."

if [ -n "$API_ADVERTISE_ADDRESSES" ]; then
  # shellcheck disable=SC2154
  kubeadm init --token "${kubeadm_token}" --pod-network-cidr=10.244.0.0/16 --kubernetes-version=v1.9.2 --apiserver-advertise-address="$API_ADVERTISE_ADDRESSES"
else
  # shellcheck disable=SC2154
  kubeadm init --token "${kubeadm_token}" --pod-network-cidr=10.244.0.0/16 --kubernetes-version=v1.9.2
fi

# Copy Kubernetes configuration created by kubeadm (admin.conf to .kube/config)
# shellcheck disable=SC2154
SSH_USER="${ssh_user}"
mkdir -p "/home/$SSH_USER/.kube/"
chown "$SSH_USER":"$SSH_USER" "/home/$SSH_USER/.kube/"
cp "/etc/kubernetes/admin.conf" "/home/$SSH_USER/.kube/config"
chown "$SSH_USER":"$SSH_USER" "/home/$SSH_USER/.kube/config"
