j# -*- mode: ruby -*-
# # vi: set ft=ruby :

require 'fileutils'
require 'open-uri'
require 'tempfile'
require 'yaml'

#
#  Custom vars
# 
cloud_prefix = "vagrant"
master_count = 1
master_vm_cpus = 2
master_vm_memory = 2048
worker_count = 1
worker_vm_memory = 2048
worker_vm_cpus = 2
edge_count = 1
edge_vm_memory = 2048
edge_vm_cpus = 2
$next_ssh_port = 3001
#bridge_interface_name = ["nothing"]
gateway = "192.168.10.1"
gateway_interface = "enp0s8"

#
#  end custom vars
#

MASTER_BOOTSTRAP_FILE = File.expand_path("bootstrap/master.sh")
NODE_BOOTSTRAP_FILE = File.expand_path("bootstrap/node.sh")

def edgeIP(num)
  return "10.0.0.#{num+20}"
end

def masterIP(num)
  return "10.0.0.#{num+10}"
end

def workerIP(num)
  return "10.0.0.#{num+30}"
end

def nextSSHPort()
  current_ssh_port = $next_ssh_port
  $next_ssh_port=$next_ssh_port + 1
  return current_ssh_port
end

Vagrant.require_version ">= 1.9.1"

Vagrant.configure("2") do |config|
  
  # Use this box for all machines
  config.vm.box = "andersla/kubenow"
  
  # always use Vagrant's insecure key
  # config.ssh.insert_key = false
  
  # fix for bento version 2.3.2
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
  end
  
  # plugin conflict
  #if Vagrant.has_plugin?("vagrant-vbguest") then
  #  config.vbguest.auto_update = false
  #end

  # No gui
  #config.vm.provider :virtualbox do |vb|
  #  vb.gui = false
  #end
  
  # Consmetic fix
  #config.vm.provision "fix-no-tty", type: "shell" do |s|
  #  s.privileged = false
  #  s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
  #end
  
  # Preferred network adapters to use as bridge (if any found - no question)
  config.vm.network "public_network"
  # The private dhcp network is only needed if using Vagrant built in nfs
  #config.vm.network "private_network", type: "dhcp"
  # All hostvars will be stored in these hashes, progressively as the VMs are made
  # and configured
  masters = {}
  edges = {}
  workers = {}
  
  firstMasterIP = masterIP(1)
  kubeadm_token = %x( ./generate_kubetoken.sh )
  
  (1..master_count).each do |i|
    config.vm.define vm_name = "#{cloud_prefix}-master-%02d" % i do |master|

      master.vm.hostname = vm_name

      master.vm.provider :virtualbox do |vb|
        vb.memory = master_vm_memory
        vb.cpus = master_vm_cpus
      end


      
      # Network
      ip4 = masterIP(i)
#      master.vm.network :public_network, "bridge": bridge_interface_name
      master.vm.network :private_network, ip: ip4
      
	  # default gateway
#      master.vm.provision "shell", run: "always", inline: "route del default"
#      master.vm.provision "shell", run: "always", inline: "route add default gw #{gateway} #{gateway_interface}"
      
      # ssh tunneling
      sshPort = nextSSHPort()
      #master.vm.network :forwarded_port, guest: 22, host: sshPort, id: 'ssh'
      
      # provision create hosts file (workaround for kubeadm bug otherwise joining nodes get vagrant nat ip number)
      master.vm.provision "shell",
                          path: "hosts.sh",
                          :privileged => true

      # provision
      master.vm.provision "shell",
                          path: MASTER_BOOTSTRAP_FILE,
                          env: {"api_advertise_addresses" => firstMasterIP,"kubeadm_token" => kubeadm_token}
      
      # provision install jq (for kubeadm workaround below)
      master.vm.provision "shell",
                          inline: "apt-get install -y jq",
                          :privileged => true

      # provision advertise-address flag in kube-apiserver static pod manifest (workaround for https://github.com/kubernetes/kubernetes/issues/34101)
      master.vm.provision "shell",
                          inline: "jq '.spec.containers[0].command |= .+ [\"--advertise-address=#{firstMasterIP}\"]' /etc/kubernetes/manifests/kube-apiserver.json > /tmp/kube-apiserver.json && mv /tmp/kube-apiserver.json /etc/kubernetes/manifests/kube-apiserver.json",
                          :privileged => true

      # provision Set --cluster-cidr flag in kube-proxy daemonset (workaround for https://github.com/kubernetes/kubernetes/issues/34101)
      #master.vm.provision "shell",
      #                    inline: "kubectl -n kube-system get ds -l 'component=kube-proxy' -o json | jq '.items[0].spec.template.spec.containers[0].command |= .+ [\"--proxy-mode=userspace\"]' | kubectl apply -f - && kubectl -n kube-system delete pods -l 'component=kube-proxy'",
      #                    :privileged => true
      
      masters[vm_name] = {
          "hostname": vm_name,
          "ansible_host": "localhost",
          "ansible_port": sshPort,
          "ip4": ip4
      }
      
      puts "masters.length = #{masters.length}"

    end
  end

  (1..edge_count).each do |i|
    config.vm.define vm_name = "#{cloud_prefix}-edge-%02d" % i do |edge|
      
      edge.vm.hostname = vm_name

      edge.vm.provider :virtualbox do |vb|
        vb.memory = edge_vm_memory
        vb.cpus = edge_vm_cpus
      end

      # Network
      ip4 = edgeIP(i)
 #     edge.vm.network :public_network, "bridge": bridge_interface_name
      edge.vm.network :private_network, ip: ip4

      # default router 
#      edge.vm.provision "shell", run: "always", inline: "route del default"
#      edge.vm.provision "shell", run: "always", inline: "route add default gw #{gateway} #{gateway_interface}"

      # ssh tunneling
      sshPort = nextSSHPort()
      #edge.vm.network :forwarded_port, guest: 22, host: sshPort, id: 'ssh'

      # provision
      edge.vm.provision "shell", path: "hosts.sh", :privileged => true

      # provision
      edge.vm.provision "shell", path: NODE_BOOTSTRAP_FILE, env: {"api_advertise_addresses" => ip4, "master_ip" => firstMasterIP,"kubeadm_token" => kubeadm_token}, :privileged => true
      
      edges[vm_name] = {
          "hostname": vm_name,
          "ansible_host": "localhost",
          "ansible_port": sshPort,
          "ip4": ip4
      }
      
    end
  end
  
  (1..worker_count).each do |i|
    config.vm.define vm_name = "#{cloud_prefix}-node-%02d" % i do |worker|
      worker.vm.hostname = vm_name

      worker.vm.provider :virtualbox do |vb|
        vb.memory = worker_vm_memory
        vb.cpus = worker_vm_cpus
      end
      
      
      
      # Network
      ip4 = workerIP(i)
      #worker.vm.network :public_network, "bridge": bridge_interface_name
      worker.vm.network :private_network, ip: ip4
      
      
      # default router 
#      worker.vm.provision "shell", run: "always", inline: "route del default"
#      worker.vm.provision "shell", run: "always", inline: "route add default gw #{gateway} #{gateway_interface}"
      
      # ssh tunneling
      sshPort = nextSSHPort()
      #orker.vm.network :forwarded_port, guest: 22, host: sshPort, id: 'ssh'
      
      # provision
      worker.vm.provision "shell", path: "hosts.sh", :privileged => true
      
      # provision
      worker.vm.provision "shell", path: NODE_BOOTSTRAP_FILE, env: {"api_advertise_addresses" => ip4, "master_ip" => firstMasterIP,"kubeadm_token" => kubeadm_token}, :privileged => true
      
      workers[vm_name] = {
          "hostname": vm_name,
          "ansible_host": "localhost",
          "ansible_port": sshPort,
          "ip4": ip4
      }
      
      if i == worker_count # create inventory last when all hosts are up
      
        inventory = "[master]\n"
        masters.each do |key, innerhash|
          inventory += "#{innerhash[:hostname]} ansible_host=#{innerhash[:ansible_host]} ansible_port=#{innerhash[:ansible_port]} ansible_user=vagrant \n"
        end
        
        inventory += "[edge]\n"
        edges.each do |key, innerhash|
          inventory += "#{innerhash[:hostname]} ansible_host=#{innerhash[:ansible_host]} ansible_port=#{innerhash[:ansible_port]} ansible_user=vagrant \n"
        end
        
        inventory += "[master:vars]\n"
        inventory += "edge_names=\""
        edges.each do |key, innerhash|
          inventory += "#{innerhash[:hostname]}"
        end
        inventory.strip!
        inventory += "\""
        invFile = File.open("inventory" ,'w')
        invFile.write inventory
        invFile.close
        
      end
      
      
    end
  end

  puts "here"

end



