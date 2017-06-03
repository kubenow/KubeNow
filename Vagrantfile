# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'
require 'open-uri'
require 'tempfile'
require 'yaml'

Vagrant.require_version ">= 1.9.1"

# Custom vars
CLUSTER_PREFIX = "kubenow"
SSH_PORT = 3001
SSH_USER = "vagrant"
MASTER_CPUS = 2
MASTER_MEMORY = 2000
GUEST_PORT_80_FORWARD = 8080
MASTER_IP = "10.0.0.11"

# Fixed vars
BRIDGE_INTERFACE_NAME = ["(optional)name_here"]
PROVIDER = "virtualbox"
DOMAIN = "127.0.0.1.nip.io"
KUBENOW_DIR = "."
KUBEADM_TOKEN = %x( "#{KUBENOW_DIR}/bin/kubetoken" )
NODE_LABELS = "role=edge"
HOSTNAME = "#{CLUSTER_PREFIX}-master-01"
ANSIBLE_HOST = "localhost"
NODES_COUNT = 1
MASTER_BOOTSTRAP_FILE = File.expand_path("#{KUBENOW_DIR}/bootstrap/master.sh")
PRIVATE_KEY_PATH = File.absolute_path(".vagrant/machines/default/#{PROVIDER}/private_key")

#
# generate inventory
#
inventory = "[master]\n"
inventory += "#{HOSTNAME} ansible_ssh_host=#{ANSIBLE_HOST} ansible_port=#{SSH_PORT} ansible_user=#{SSH_USER} ansible_ssh_private_key_file=\"#{PRIVATE_KEY_PATH}\"\n"

inventory += "[edge]\n"
inventory += "#{HOSTNAME} ansible_ssh_host=#{ANSIBLE_HOST} ansible_port=#{SSH_PORT} ansible_user=#{SSH_USER} ansible_ssh_private_key_file=\"#{PRIVATE_KEY_PATH}\"\n"

inventory += "[master:vars]\n"
inventory += "edge_names=\""

inventory += "#{HOSTNAME} "

inventory.strip!
inventory += "\"" + "\n"

inventory += "[all:vars]\n"
nodes_count = 1
inventory += "nodes_count=#{NODES_COUNT}" + "\n"
inventory += "domain=#{DOMAIN}" + "\n"
inventory += "http_port=#{GUEST_PORT_80_FORWARD}" + "\n"
inventory += "provider=vagrant"

invFile = File.open("inventory" ,'w')
invFile.write inventory
invFile.close

Vagrant.configure("2") do |config|

  config.vm.box = "kubenow/kubenow"
  config.vm.box_version = "0.0.6"
  config.vm.hostname = HOSTNAME
  config.vm.provider :virtualbox do |vb|
    vb.memory = MASTER_MEMORY
    vb.cpus = MASTER_CPUS
  end

  # fix for bento version 2.3.2 = kubenow base image
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  # no gui
  config.vm.provider :virtualbox do |vb|
    vb.gui = false
  end

  # consmetic fix
  config.vm.provision "fix-no-tty", type: "shell" do |s|
    s.privileged = false
    s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
  end

  # network
  config.vm.network :private_network, ip: MASTER_IP,
                                      netmask: "255.255.255.0",
                                      bridge: BRIDGE_INTERFACE_NAME,
                                      auto_config: true,
                                      virtualbox__intnet: "kubenow-net"

  # ssh tunneling
  config.vm.network :forwarded_port, guest: 22, host: SSH_PORT, id: 'ssh'

  # map guest port 80 to host port xx on edge
  config.vm.network :forwarded_port, guest: 80, host: GUEST_PORT_80_FORWARD

  # disable vagrant default shared folders
  config.vm.synced_folder '.', '/vagrant', disabled: true

  # disable ssh password logon
  config.vm.provision "shell",
                       inline: "sed -i -e 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config &&
                                sed -i -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config &&
                                service ssh restart",
                       :privileged => true

  # bootstrap (kubeadm init)
  config.vm.provision "shell",
                      path: MASTER_BOOTSTRAP_FILE,
                      env: {"kubeadm_token" => KUBEADM_TOKEN,"ssh_user" => SSH_USER, "node_labels" => NODE_LABELS}

end
