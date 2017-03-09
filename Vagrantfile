# -*- mode: ruby -*-
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
master_cpus = 2
master_memory = 1500
$edge_count = 1
edge_memory = 1500
edge_cpus = 2
$node_count = 1
node_memory = 5096
node_cpus = 3
guest_port_80_forward = 8080

#
#  end custom vars
#

# currently we only support one master node
$master_count = 1
bridge_interface_name = ["(optional)name_here"]
provider = "virtualbox"
domain = "#{$cluster_prefix}.local"
firstMasterIP = "10.0.0.11";
kubenow_dir = "."
kubeadm_token = %x( "#{kubenow_dir}/generate_kubetoken.sh" )
puts kubeadm_token
MASTER_BOOTSTRAP_FILE = File.expand_path("#{kubenow_dir}/bootstrap/master.sh")
NODE_BOOTSTRAP_FILE = File.expand_path("#{kubenow_dir}/bootstrap/node.sh")

$next_ssh_port = first_ssh_port
def nextSSHPort()
  current_ssh_port = $next_ssh_port
  $next_ssh_port =  $next_ssh_port +1;
  return current_ssh_port
end

# generate settings for all nodes into this hash
machines = {}
(1..$master_count).each do |i|
 
  type = "master"
  name = "#{$cluster_prefix}-#{type}-%02d" % i
  machines[name] = {
                "type": type,
                "hostname": name,
                "memory": master_memory,
                "cpus": master_cpus,
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
                "memory": edge_memory,
                "cpus": edge_cpus,
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
                "memory": node_memory,
                "cpus": node_cpus,
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
machines.each do |key, settings|
  if settings[:type] == "master"
    inventory += "#{settings[:hostname]} ansible_host=#{settings[:ansible_host]} ansible_port=#{settings[:ssh_port]} ansible_user=vagrant ansible_ssh_private_key_file=\"#{settings[:private_key_path]}\"\n"
  end
end

inventory += "[edge]\n"
machines.each do |key, settings|
  if settings[:type] == "edge"
    inventory += "#{settings[:hostname]} ansible_host=#{settings[:ansible_host]} ansible_port=#{settings[:ssh_port]} ansible_user=vagrant ansible_ssh_private_key_file=\"#{settings[:private_key_path]}\"\n"
  end
end

inventory += "[master:vars]\n"
inventory += "edge_names=\""
machines.each do |key, settings|
  if settings[:type] == "edge"
    inventory += "#{settings[:hostname]} "
  end
end

inventory.strip!
inventory += "\"" + "\n"

inventory += "[all:vars]\n"
nodes_count = $master_count + $edge_count + $node_count;
inventory += "nodes_count=#{nodes_count}" + "\n"
inventory += "domain=#{domain}" + "\n"
inventory += "http_port=#{guest_port_80_forward}" + "\n"
inventory += "provider=vagrant"

invFile = File.open("inventory" ,'w')
invFile.write inventory
invFile.close

#
# generate command to edit /etc/hosts
#
append_hosts_cmd = ""
machines.each do |key, settings|
  append_hosts_cmd += "echo " + settings[:ip4] + " " + settings[:hostname] + " >> /etc/hosts;"
end

Vagrant.configure("2") do |config|

  # Use this box for all machines
  config.vm.box = "kubenow/kubenow"
  config.vm.box_version = "0.2.0.a"
  
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
  
  # deploy the machines
  machines.each do |key, settings|
    config.vm.define vm_name = settings[:hostname] do |machine|

      machine.vm.hostname = settings[:hostname]

      machine.vm.provider :virtualbox do |vb|
        vb.memory = settings[:memory]
        vb.cpus = settings[:cpus]
      end
      
      # network
      machine.vm.network :private_network, ip: settings[:ip4],
                                           netmask: "255.255.255.0", 
                                           bridge: bridge_interface_name,
                                           auto_config: true,
                                           virtualbox__intnet: "kubenow-net"
      
      # ssh tunneling
      machine.vm.network :forwarded_port, guest: 22, host: settings[:ssh_port], id: 'ssh'
      
      # map guest port 80 to host port xx on edge servers
      if settings[:type] == "edge"
        machine.vm.network :forwarded_port, guest: 80, host: guest_port_80_forward
      end

      # disable vagrant default shared folders
      machine.vm.synced_folder '.', '/vagrant', disabled: true
      
      # disable ssh password logon
      machine.vm.provision "shell",
                           inline: "sed -i -e 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config && 
                                    sed -i -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config &&  
                                    service ssh restart",
                           :privileged => true
      
      # edit hosts file (workaround for kubeadm bug otherwise joining nodes get vagrant nat ip number)
      machine.vm.provision "shell",
                          inline: append_hosts_cmd,
                          :privileged => true

      # bootstrap (kubeadm init)
      machine.vm.provision "shell",
                          path: settings[:bootstrap_file],
                          env: {"api_advertise_addresses" => firstMasterIP, "master_ip" => firstMasterIP, "kubeadm_token" => kubeadm_token}
      
      
      # only master need these fixes (and has to be run in this order)
      if settings[:type] == "master"
        # Set --proxy-mode flag in kube-proxy daemonset (workaround for https://github.com/kubernetes/kubernetes/issues/34101)
        machine.vm.provision "shell",
                            inline: "kubectl -n kube-system get ds -l \"component=kube-proxy\" -o json | jq \".items[0].spec.template.spec.containers[0].command |= .+ [\\\"--proxy-mode=userspace\\\"]\" | kubectl apply -f - && kubectl -n kube-system delete pods -l \"component=kube-proxy\"",
                            :privileged => true                          

        # advertise-address flag in kube-apiserver static pod manifest (workaround for https://github.com/kubernetes/kubernetes/issues/34101)
        machine.vm.provision "shell",
                            inline: "jq '.spec.containers[0].command |= .+ [\"--advertise-address=#{firstMasterIP}\"]' /etc/kubernetes/manifests/kube-apiserver.json > /tmp/kube-apiserver.json && mv /tmp/kube-apiserver.json /etc/kubernetes/manifests/kube-apiserver.json",
                            :privileged => true
      end
      
      
          
    end
  end
end
      
 
