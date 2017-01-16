j# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'
require 'open-uri'
require 'tempfile'
require 'yaml'

#
#  Custom vars
# 
$cluster_prefix = "vagrant"
first_ssh_port = 3001

master_cpus = 2
master_memory = 2048
$edge_count = 1
edge_memory = 2048
edge_vm_cpus = 2
$node_count = 1
node_memory = 2048
node_cpus = 2

#
#  end custom vars
#
bridge_interface_name = ["(optional)name_here"]
provider = "virtualbox"

MASTER_BOOTSTRAP_FILE = File.expand_path("bootstrap/master.sh")
NODE_BOOTSTRAP_FILE = File.expand_path("bootstrap/node.sh")

def masterIP(num)
  return "10.0.0.#{num+10}"
end
def masterName(num)
  name = "#{$cluster_prefix}-master-%02d" % num
  return name
end

def edgeIP(num)
  return "10.0.0.#{num+20}"
end
def edgeName(num)
  return "#{$cluster_prefix}-edge-%02d" % num
end

def nodeIP(num)
  return "10.0.0.#{num+30}"
end
def nodeName(num)
  return "#{$cluster_prefix}-node-%02d" % num
end

$next_ssh_port = first_ssh_port
def nextSSHPort()
  current_ssh_port = $next_ssh_port
  $next_ssh_port=$next_ssh_port + 1
  return current_ssh_port
end

$master_count = 1
def appendHostsCmd()
   hostCmd = ""
  (1..$master_count).each do |i|
      hostCmd += "echo " + masterIP(i) + " " + masterName(i) + " >> /etc/hosts;"
  end
  (1..$edge_count).each do |i|
      hostCmd += "echo " + edgeIP(i) + " " + edgeName(i) + " >> /etc/hosts;"
  end
  (1..$node_count).each do |i|
      hostCmd += "echo " + nodeIP(i) + " " + nodeName(i) + " >> /etc/hosts;"
  end
  return hostCmd
end

Vagrant.require_version ">= 1.9.1"

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
  
  # All hostvars will be stored in these hashes, progressively as the VMs are made
  # and configured
  masters = {}
  edges = {}
  nodes = {}
  
  firstMasterIP = masterIP(1)
  kubeadm_token = %x( ./generate_kubetoken.sh )
  
  (1..$master_count).each do |i|
    config.vm.define vm_name = masterName(i) do |master|

      master.vm.hostname = vm_name

      master.vm.provider :virtualbox do |vb|
        vb.memory = master_memory
        vb.cpus = master_cpus
      end
      
      # network
      ip4 = masterIP(i)
      master.vm.network :private_network, ip: ip4, netmask: "255.255.255.0", bridge: bridge_interface_name, auto_config: true, virtualbox__intnet: "kubenow-net"
      
      # ssh tunneling
      sshPort = nextSSHPort()
      master.vm.network :forwarded_port, guest: 22, host: sshPort, id: 'ssh'
      
      # disable shared folders
      master.vm.synced_folder '.', '/vagrant', disabled: true
      
      # edit hosts file (workaround for kubeadm bug otherwise joining nodes get vagrant nat ip number)
      master.vm.provision "shell",
                          inline: appendHostsCmd(),
                          :privileged => true

      # bootstrap (kubeadm init)
      master.vm.provision "shell",
                          path: MASTER_BOOTSTRAP_FILE,
                          env: {"api_advertise_addresses" => firstMasterIP,"kubeadm_token" => kubeadm_token}

      # advertise-address flag in kube-apiserver static pod manifest (workaround for https://github.com/kubernetes/kubernetes/issues/34101)
      master.vm.provision "shell",
                          inline: "jq '.spec.containers[0].command |= .+ [\"--advertise-address=#{firstMasterIP}\"]' /etc/kubernetes/manifests/kube-apiserver.json > /tmp/kube-apiserver.json && mv /tmp/kube-apiserver.json /etc/kubernetes/manifests/kube-apiserver.json",
                          :privileged => true
      
      # add metadata for inventory
      masters[vm_name] = {
          "hostname": vm_name,
          "ansible_host": "localhost",
          "ansible_port": sshPort,
          "ip4": ip4
      }
      
    end
  end

  (1..$edge_count).each do |i|
    config.vm.define vm_name = edgeName(i) do |edge|
      
      edge.vm.hostname = vm_name

      edge.vm.provider :virtualbox do |vb|
        vb.memory = edge_memory
        vb.cpus = edge_vm_cpus
      end
         
      # network
      ip4 = edgeIP(i)
      edge.vm.network :private_network, ip: ip4, netmask: "255.255.255.0", bridge: bridge_interface_name, auto_config: true, virtualbox__intnet: "kubenow-net"

      # ssh tunneling
      sshPort = nextSSHPort()
      edge.vm.network :forwarded_port, guest: 22, host: sshPort, id: 'ssh'

      # disable shared folders
      edge.vm.synced_folder '.', '/vagrant', disabled: true

      # edit hosts file (workaround for kubeadm bug otherwise joining nodes get vagrant nat ip number)
      edge.vm.provision "shell",
                         inline: appendHostsCmd(),
                         :privileged => true

      # bootstrap (kubeadm join)
      edge.vm.provision "shell", path: NODE_BOOTSTRAP_FILE, env: {"master_ip" => firstMasterIP,"kubeadm_token" => kubeadm_token}, :privileged => true
      
      # add metadata for inventory
      edges[vm_name] = {
          "hostname": vm_name,
          "ansible_host": "localhost",
          "ansible_port": sshPort,
          "ip4": ip4
      }
      
    end
  end
  
  (1..$node_count).each do |i|
    config.vm.define vm_name = nodeName(i) do |node|
      node.vm.hostname = vm_name

      node.vm.provider :virtualbox do |vb|
        vb.memory = node_memory
        vb.cpus = node_cpus
      end
       
      # network
      ip4 = nodeIP(i)
      node.vm.network :private_network, ip: ip4, netmask: "255.255.255.0", bridge: bridge_interface_name, auto_config: true, virtualbox__intnet: "kubenow-net"
      
      # ssh tunneling
      sshPort = nextSSHPort()
      node.vm.network :forwarded_port, guest: 22, host: sshPort, id: 'ssh'
      
      # disable shared folders
      node.vm.synced_folder '.', '/vagrant', disabled: true
      
      # edit hosts file (workaround for kubeadm bug otherwise joining nodes get vagrant nat ip number)
      node.vm.provision "shell",
                          inline: appendHostsCmd(),
                          :privileged => true
      
      # bootstrap (kubeadm join)
      node.vm.provision "shell", path: NODE_BOOTSTRAP_FILE, env: {"master_ip" => firstMasterIP,"kubeadm_token" => kubeadm_token}, :privileged => true
      
      # add metadata for inventory
      nodes[vm_name] = {
          "hostname": vm_name,
          "ansible_host": "localhost",
          "ansible_port": sshPort,
          "ip4": ip4
      }
      
      #
      # create inventory last when all hosts are up
      #
      if i == $node_count
      
        inventory = "[master]\n"
        masters.each do |key, innerhash|
          private_key_path = File.absolute_path(".vagrant/machines/#{innerhash[:hostname]}/#{provider}/private_key")
          inventory += "#{innerhash[:hostname]} ansible_host=#{innerhash[:ansible_host]} ansible_port=#{innerhash[:ansible_port]} ansible_user=vagrant ansible_ssh_private_key_file=\"#{private_key_path}\"\n"
        end
        
        inventory += "[edge]\n"
        edges.each do |key, innerhash|
          private_key_path = File.absolute_path(".vagrant/machines/#{innerhash[:hostname]}/#{provider}/private_key")
          inventory += "#{innerhash[:hostname]} ansible_host=#{innerhash[:ansible_host]} ansible_port=#{innerhash[:ansible_port]} ansible_user=vagrant ansible_ssh_private_key_file=\"#{private_key_path}\"\n"
        end
        
        inventory += "[master:vars]\n"
        inventory += "edge_names=\""
        edges.each do |key, innerhash|
          inventory += "#{innerhash[:hostname]} "
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
        
      end
      
      
    end
  end

end



