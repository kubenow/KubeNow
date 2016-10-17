Welcome to the KubeNow wiki! This is a place where we aim to help you to provision Kubernetes, the KubeNow's way. If you are new to Kubernetes, and to cloud computing, this is going to take a while to grasp the first time. Luckily, once you get the procedure, it's going to be very quick to spawn your clusters.

# Getting Started

## Step 0: Prerequisites 

### Install provisioning tools
There are 3 tools that you need to install on your local machine, in order to provision Kubernetes with KubeNow:

- [Packer](https://www.packer.io/) to build a KubeNow cloud image on the host cloud
- [Terraform](https://www.terraform.io/) to fire-up the virtual infrastructure on the host cloud
- [Ansible](https://www.ansible.com/) to provision the VMs (e.g. install and configure networking, reverse proxy etc.)

### Get KubeNow
To get KubeNow please clone its repository.

```bash
git clone https://github.com/mcapuccini/KubeNow.git
cd KubeNow
git checkout v0.0.1-beta1 # switch to latest relase
```

We assume that all of the commands in this wiki are being run in the KubeNow directory.

## Step 1: Bootstrap Kubernetes on a host cloud
This step depends on the cloud provider that your are going to use. Here you find a tutorial for each of the supported providers:

- [Bootstrap on OpenStack](Bootstrap Kubernetes on OpenStack)

## Step 2: Install add-ons

If you completed the previous steps, you should have a core Kubernetes cluster up and running, on your cloud provider. **Your cluster is not ready to be used yet**. You can finish the installation running the [add-ons.yml](https://github.com/mcapuccini/KubeNow/blob/master/playbooks/add-ons.yml) playbook, using [Ansible](https://www.ansible.com/):

```bash
ansible-playbook playbooks/add-ons.yml
```

The [add-ons.yml](https://github.com/mcapuccini/KubeNow/blob/master/playbooks/add-ons.yml) playbook installs:

 - [Weave](https://www.weave.works/) networking
 - [Traefik](https://traefik.io/) HTTP reverse proxy and load balancer
 - [Kubernetes Dashboard](http://kubernetes.io/docs/user-guide/ui/)

If you are just making your first steps with Kubernetes, this deployment is what we recommend. However, if you'd like a lighter Kubernetes installation you can comment out the `dashboard` and the `traefik` roles before running the previous playbook. When you comment out `traefik` the edge nodes will act as regular Kubernetes nodes. 

This software installation with Ansible is only needed on the master and edge nodes, on the worker nodes everything needed is already on the image built with Packer. Since the workers does not need additional software installed with Ansible, they do not need to have public ip's.

## Step 3: Configure DNS records 
The edge nodes act as getaways to access some services running in the Kubernetes nodes. Typically, you want the end user to access your services through a domain name. One option is to manually configure the DNS services, for a domain name, to load balance the requests among the edge nodes. However, doing this for each deployment can be tedious, and and prone to configuration errors. Hence, we recommend to sign up for a free account on [CluodFlare](https://www.cloudflare.com/), that you can use as dynamic DNS service for your domain name.

### Automatic configuration using CloudFlare

Start by creating a `playbooks/roles/cloudflare/vars/conf.yml` configuration file. There is a template file that you can use for your convenience: 

```
mv playbooks/roles/cloudflare/vars/conf.yml.template playbooks/roles/cloudflare/vars/conf.yml
```

In this configuration file you need to set:

- **cf_mail**: the mail that you used to register your CloudFlare account
- **cf_token**: an authentication token that you can generate from the CloudFlare web interface
- **cf_zone**: a zone that you created in your CloudFlare account. This typically matches your domain name (e.g. somedomain.com)
- **cf_subdomain** (optional): you can set a subdomain name for this cluster, if you don't want to use the whole domain for this purpose

Once you are done with your settings, you can configure your DNS records by running:

```bash
# NOTE Ansible version 2.1 or later is needed
ansible-playbook playbooks/cloudflare-add.yml
```

### Next steps
Congratulations! If you followed the previous steps, and you didn't get any error, your Kubernetes cluster is now up and running. You may want to continue with any of these tutorials:

- [Access the Dashboard and the Traefik UIs](Access the Dashboard and the Traefik UIs)
- [Deploy your first application](Deploy your first application)
- [Destroy the cluster](Destroy the cluster)
- [Troubleshooting](Troubleshooting)

