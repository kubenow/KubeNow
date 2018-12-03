#!/bin/bash

# Add hostname
echo "127.0.0.1 $HOSTNAME" >>/etc/hosts

if [[ "${use_external_net}" == "1" || $(echo ${use_external_net} | tr '[:upper:]' '[:lower:]') == "true" ]]; then
  # Detect name of the secondary interface
  interfaces=$(cat /proc/net/dev | grep ens | cut -d':' -f1)
  primary_interface=$(echo $interfaces | cut -d' ' -f1)
  secondary_interface=$(echo $interfaces | cut -d' ' -f2)

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

# make sure swap is off
sudo swapoff -a
# make sure any line with swap is removed from fstab
sudo sed -i '/swap/d' /etc/fstab

echo "Try to join master..."
# shellcheck disable=SC2154
kubeadm join --discovery-token-unsafe-skip-ca-verification --token "${kubeadm_token}" "${master_ip}:6443"
