j# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'
require 'open-uri'
require 'tempfile'
require 'yaml'

Vagrant.require_version ">= 1.9.1"

#
#  Custom vars
# 
$cluster_prefix = "kubenow"
first_ssh_port = 3001

master_cpus = 1
master_memory = 1500
$edge_count = 1
edge_memory = 1500
edge_vm_cpus = 1
$node_count = 1
node_memory = 1500
node_cpus = 1

#
#  end custom vars
#

$master_count = 1
bridge_interface_name = ["(optional)name_here"]
provider = "virtualbox"
firstMasterIP = "10.0.0.11";
kubeadm_token = %x( ./generate_kubetoken.sh )

MASTER_BOOTSTRAP_FILE = File.expand_path("bootstrap/master.sh")
NODE_BOOTSTRAP_FILE = File.expand_path("bootstrap/node.sh")

$next_ssh_port = first_ssh_port
def nextSSHPort()
  current_ssh_port = $next_ssh_port
  $next_ssh_port=$next_ssh_port + 1
  return current_ssh_port
end

# All hostvars are be stored in these hashes
machines = {}
(1..$master_count).each do |i|
 
  type = "master"
  name = "#{$cluster_prefix}-#{type}-%02d" % i
  machines[name] = {
                "type": type,
                "hostname": name,
                "ansible_host": "localhost",
                "ssh_port": nextSSHPort(),
                "ip4": "10.0.0.#{i+10}",
                "bootstrap_file": MASTER_BOOTSTRAP_FILE,
                "private_key_path": File.absolute_path(".vagrant/machines/#{name}/#{provider}/private_key")
               }               
end

(1..$edge_count).each do |i|
  
  type = "edge"
  name = "#{$cluster_prefix}-#{type}-%02d" % i
  machines[name] = {
                "type": type,
                "hostname": name,
                "ansible_host": "localhost",
                "ssh_port": nextSSHPort(),
                "ip4": "10.0.0.#{i+20}",
                "bootstrap_file": NODE_BOOTSTRAP_FILE,
                "private_key_path": File.absolute_path(".vagrant/machines/#{name}/#{provider}/private_key")
               }
end

(1..$node_count).each do |i|
  
  type = "node"
  name = "#{$cluster_prefix}-#{type}-%02d" % i
  machines[name] = {
                "type": type,
                "hostname": name,
                "ansible_host": "localhost",
                "ssh_port": nextSSHPort(),
                "ip4": "10.0.0.#{i+30}",
                "bootstrap_file": NODE_BOOTSTRAP_FILE,
                "private_key_path": File.absolute_path(".vagrant/machines/#{name}/#{provider}/private_key")
               }
end

#
# generate inventory
#
inventory = "[master]\n"
machines.each do |key, innerhash|
  if innerhash[:type] == "master"
    inventory += "#{innerhash[:hostname]} ansible_host=#{innerhash[:ansible_host]} ansible_port=#{innerhash[:ssh_port]} ansible_user=vagrant ansible_ssh_private_key_file=\"#{innerhash[:private_key_path]}\"\n"
  end
end

inventory += "[edge]\n"
machines.each do |key, innerhash|
  if innerhash[:type] == "edge"
    inventory += "#{innerhash[:hostname]} ansible_host=#{innerhash[:ansible_host]} ansible_port=#{innerhash[:ssh_port]} ansible_user=vagrant ansible_ssh_private_key_file=\"#{innerhash[:private_key_path]}\"\n"
  end
end

inventory += "[master:vars]\n"
inventory += "edge_names=\""
machines.each do |key, innerhash|
  if innerhash[:type] == "edge"
    inventory += "#{innerhash[:hostname]} "
  end
end

inventory.strip!
inventory += "\"" + "\n"

inventory += "[all:vars]\n"
nodes_count = $master_count + $edge_count + $node_count;
inventory += "nodes_count=#{nodes_count}" + "\n"
inventory += "provider=vagrant"

invFile = File.open("inventory" ,'w')
invFile.write inventory
invFile.close

#
# generate edit /etc/hosts command
#
append_hosts_cmd = ""
machines.each do |key, innerhash|
  append_hosts_cmd += "echo " + innerhash[:ip4] + " " + innerhash[:hostname] + " >> /etc/hosts;"
end

Vagrant.configure("2") do |config|

  # Use this box for all machines
  config.vm.box = "kubenow/kubenow"
  config.vm.box_version = "0.0.2"
  
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
  
  # eploy the machines
  machines.each do |key, innerhash|
    config.vm.define vm_name = innerhash[:hostname] do |machine|

      machine.vm.hostname =innerhash[:hostname]

      machine.vm.provider :virtualbox do |vb|
        vb.memory = master_memory
        vb.cpus = master_cpus
      end
      
      # network
      machine.vm.network :private_network, ip: innerhash[:ip4], netmask: "255.255.255.0", bridge: bridge_interface_name, auto_config: true, virtualbox__intnet: "kubenow-net"
      
      # ssh tunneling
      machine.vm.network :forwarded_port, guest: 22, host: innerhash[:ssh_port], id: 'ssh'
      
      # disable shared folders
      machine.vm.synced_folder '.', '/vagrant', disabled: true
      
      # edit hosts file (workaround for kubeadm bug otherwise joining nodes get vagrant nat ip number)
      machine.vm.provision "shell",
                          inline: append_hosts_cmd,
                          :privileged => true

      # bootstrap (kubeadm init)
      machine.vm.provision "shell",
                          path: innerhash[:bootstrap_file],
                          env: {"api_advertise_addresses" => firstMasterIP, "master_ip" => firstMasterIP, "kubeadm_token" => kubeadm_token}
      
      if innerhash[:type] == "master"
        # advertise-address flag in kube-apiserver static pod manifest (workaround for https://github.com/kubernetes/kubernetes/issues/34101)
        machine.vm.provision "shell",
                            inline: "jq '.spec.containers[0].command |= .+ [\"--advertise-address=#{firstMasterIP}\"]' /etc/kubernetes/manifests/kube-apiserver.json > /tmp/kube-apiserver.json && mv /tmp/kube-apiserver.json /etc/kubernetes/manifests/kube-apiserver.json",
                            :privileged => true
      end
          
    end
  end
end
      
 
