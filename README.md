# KubeNow
<<<<<<< HEAD
Deploy Kubernetes on OpenStack. Now!
=======

#### -- Please note this is still a Beta project -- 

Using KubeNow you can rapidly deploy, and tear down a [Kubernetes](http://kubernetes.io/) clusters on OpenStack (GCE and other cloud providers are on the roadmap).
<br>
The aim of KubeNow is to be a semi-automatic, transparent (not a black box) pipeline for provisioning and deploying a Kubernetes cluster. It does so by providing an easy to maintain set of configuration files and templates for the provisioning and deployment tools. It uses [Terraform](https://www.terraform.io/), [kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm/), [Ansible](https://www.ansible.com/) and [Packer](https://www.packer.io/) to perform the tasks.

Deploying a KubeNow cluster you will get:

- A Kubernetes cluster up and running in less than 5 min, including:
 - [Weave](https://www.weave.works/) networking
 - [Traefic](https://traefik.io/) HTTP reverse proxy and load balancer
 - Kubernetes [Dashboard](http://kubernetes.io/docs/user-guide/ui/)
 - Clodflare DNS integration

# Table of contents

- [Getting started](#getting-started)
  - [0.5 Overview of process](0.5-Overview-of-process)
  - [1. Install Packer, Terraform and Ansible](#1.-Install-Packer,-Terraform-and-Ansible)
  - [2. Get KubeNow](#2.-Get-KubeNow)
  - [2.5 Prepare your OpenStack tenancy](#2.5-Prepare-your-OpenStack-tenancy)
  - [3. With-Packer: Build the Image for the nodes](#3.-With-Packer:-Build-the-Image-for-the-nodes)
  - [4. With Terraform: Provision the infrastructure](#4.-With-Terraform:-Provision-the-infrastructure)
  - [5. With Ansible: Configure the nodes/install additional features](#5.-With-Ansible:-Configure-the-nodes/install-additional-features)
  - [6. Access Kubernetes Dashboard and Traefic web-ui](#6.-Access-Kubernetes-Dashboard-and-Traefic-web-ui)
  - [7. Scale the cluster](#7.-Scale-the-cluster)
  - [8. Destroy the cluster](#8.-Destroy-the-cluster)

# Getting started

### 0.5 Overview of process
- To speed up deployment of the cluster the first step is to create an image with (most) of the nodes software pre-installed or downloaded - this is done with Packer. (Ubuntu 16.04 is the starting image).
- The second step is to provision the infrastructure of cluster nodes at the cloud provider, this is done with Terraform and all nodes are started with the pre-installed image created with Packer in the previous step. This step is also starting the kubernetes service on the nodes and joining the master and workers together into a cluster.
- Finally some minimal, additional configuration and installation of the nodes is done with Ansible.

### 1. Install Packer, Terraform and Ansible
On your local computer: KubeNow uses Packer (https://www.packer.io/) and Terraform (https://www.terraform.io/), to build
its OpenStack image and to provision the cluster. Please install all of them on your local machine,
following the instruction on their websites.
KubeNow also uses Ansible (https://www.ansible.com/) to install and or configure additional components (Weave, Traefic, Dashboard) when the cluster is up and running.<br>

```
Please note that sometimes different versions of the above tools might cause errors
in the provisioning/deployment pipeline, we have tested the following combination:

Packer: 0.10.1
Terraform: 0.6.16
Ansible: 2.0.0.2
```

### 2. Get KubeNow
To get KubeNow just clone this repository.

```bash
git clone https://github.com/mcapuccini/KubeNow.git
# move into the directory
cd KubeNow
```

### 2.5 Prepare your OpenStack tenancy

You need to set up some things manually in your OpenStack project (on the roadmap of KubeNow this is to be done with Terraform modules in the future):

Make sure you have your OpenStack RC-file (credentials) `my_project-openrc.sh` - If not: Access your OpenStack tenancy through the web interface, download the OpenStack RC file (Compute > Access & Security > API Access & Security > Download OpenStack RC FILE)

Keypair - Make sure you have a ssh KeyPair added to your OpenStack pjoject.

Network - In OpenStack you need to have/create a local network for your kubernetes nodes to attach (e.g. an internal network (e.g. 10.3.0.0/24) connected with a router to the external Internet network)

You need to have at least 2 available floating ip:s (one for the master node and one for the edge node)

### 3. With Packer: Build the Image for the nodes

The packer build file [packer/build.json](packer/build.json) is in is in directory: [packer/](packer/) - included in this directory is also the shell script [packer/requirements.sh](packer/requirements.sh) that packer is executing on the node that will be imaged, this shell script is installing the software requirements (e.g. Kubernetes, Docker, Weave, Traefic)

All variable settings needed for packer in [packer/build.json](packer/build.json) should be defined in packer-conf.json (there is a template you can rename and edit: [packer-conf.json.template](packer-conf.json.template))

```bash
{
  "image_name": "KubeNow",
  "source_image_name": "Ubuntu 16.04",
  "network": "19he280e-ce1b-4300-9d6a-de645eejhefef",
  "flavor": "s1.medium",
  "floating_ip_pool": "my_pool_name"
}
```
```bash
# Make sure you have your OpenStack credentials in the local environment
# (source your credential file downloaded in step "Prepare your OpenStack tenancy")
source my_project-openrc.sh # you will be asked to type your password

# Now run packer to build image
packer build -var-file=packer-conf.json packer/build.json
```
If everything goes well, you will see the new image in the OpenStack web interface (Compute > Images).
Or you can use nova to list images:
```bash
nova image-list
```

>**Debug this step:**
>
> - What version of Packer are you using?
> - 

### 4. With Terraform: Provision the infrastructure

Terraform is creating the nodes on your tenancy. The image created with Packer will be the installed image. The last step in the Terraform provisioning process is to execute a bash-script located in directory [bootstrap/](bootstrap/) on the nodes that starts the kubernetes service on the nodes and join the master and workers together into a cluster.

The terraform "modules" (scripts) provisioning the infrastructure are in directory [openstack/](openstack/)
All user variable settings needed for terraform main "module" [openstack/main.tf](openstack/main.tf) should be defined in terraform.tfvars (there is a template you can rename and edit: [terraform.tfvars.template](terraform.tfvars.template))

You can use [generate_kubetoken.sh](generate_kubetoken.sh) to generate a valid token variable.

```bash
cluster_prefix = "my_KubeNow"
KuberNow_image = "KubeNow" # Name of image created with Packer
keypair_name = "my-clud-keypair" # Name of Keypair in OpenStack project (for ssh node access)
private_network = "my_internal_net_name" # Name(Label) of the network to attach the nodes to
kubeadm_token = "c52ddf.f9324a7fa5058c6f" # you can run generate_kubetoken.sh to create a valid token

master_flavor = "s1.medium" # a to small node might cause diffuse errors on your installation
floating_ip_pool = "ip_pool_name"

node_count = "3"
node_flavor = "s1.medium" # a to small node might cause diffuse errors on your installation

edge_count = "1"
edge_flavor = "s1.medium" # a to small node might cause diffuse errors on your installation
```
```bash
# Make sure you have your OpenStack credentials in the local environment
# (source your credential file downloaded in step "Prepare your OpenStack tenancy")
source myproject-openrc.sh # you will be asked to type your password

# Now run terraform
terraform get openstack # download terraform modules (required only the first time you deploy)
terraform apply -var-file=terraform-citycloud.tfvars openstack # deploy the cluster
```
If everity goes well, something like the following will be printed:

```bash
Apply complete! Resources: XX added, 0 changed, 0 destroyed.
```

It will still take some time for the worker/edge nodes to join the master node and form the cluster

To verify that everything is ready, execute the following command until you see that they are all ready:

```bash
# see that all nodes are joined together
ansible my_KubeNow-master -a "kubectl get nodes"

```
If this not is working check boot log of master node and/or the worker nodes - see Debug this step below

If you want to see the logs of the nodes please use:
```bash
nova list
nova console-log <uuid>
```
>**Debug this step:**
>
> Itf you are having problems with terraform, one usual problem is that the terraform saved state files are out of sync with your infrastructure, remove all state files and cached modules:
>```bash
> .terraform/ # remove this directory
> terraform.tfstate # remove this file
> terraform.tfstate.backup # remove this file
> ```
>
>To list your nodes ip and id numbers:
>```bash
># get list of node id:s
>nova list
>```
>To see log (boot and install log) on your nodes:
>```bash
># get list of node id:s
>nova list
>
># show console output from node of interest
>nova console-log <id of node of interest>
>```

### 5. With Ansible: Configure the nodes/install additional features
Terraform should have created an ansible "inventory" file in your working directory

Install and configure the nodes with Ansible (e.g. Weave, Traefic, Dashboard)
```bash
ansible-playbook playbooks/add-ons.yml
```

If you want to configure Cloudflare DNS
Add your domain to....TODO

```bash
ansible-playbook playbooks/cloudflare-add.yml

# to remove cloudflare record
ansible-playbook playbooks/cloudflare-rm.yml
```

If you want to create ssh-tunneling to access Dashbord and Traefic web interface: - See below (6. Access Kubernetes Dashboard and Traefic web-ui)

>**Debug this step:**
>
>Is the inventory file ok?
>```bash
>cat inventory
>```
>What version of Ansible?
>

### 6. Access Kubernetes Dashboard and Traefic web-ui

The best way to access the UIs is through ssh port forwarding. We discourage to open the ports in the security group. In above step you could set up port forward in a simple step with ansible

You can create tunneling by simply executing the included playbooks:
```bash
# to add ssh tunneling
ansible-playbook playbooks/ui-tunnels-add.yml

# to remove ssh tunneling
ansible-playbook playbooks/ui-tunnels-rm.yml
```
If everything went well, you should be able to access the UIs from your browser at the following addresses.

    Dashboard UI: http://localhost:8001
    Traefic: http://localhost:90
    
>**Debug this step:**
>
> TODO

### 7. Scale the cluster

    In the future:)

### 8. Destroy the cluster

To destroy the cluster and release all of the resources, you can run the following command:

```bash
# Make sure you have your OpenStack credentials in the local environment
# (source your credential file downloaded in step "Prepare your OpenStack tenancy")
source myproject-openrc.sh # you will be asked to type your password

# destroy the infrastructure (release the resources)
terraform destroy -var-file=terraform.tfvars openstack
```

>**Debug this step:**
>
>TODO

>>>>>>> cc09f9d... Edited README
