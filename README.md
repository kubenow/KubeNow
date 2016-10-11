# KubeNow

Using KubeNow you can rapidly deploy, scale, and tear down your Kubernetes clusters on any cloud. 

## Approach
Rather than providing an all-in-one tool for provisioning a Kubernetes cluster (e.g. [Juju](https://jujucharms.com/) and [Kubespray](https://github.com/kubespray/kargo-cli)), KubeNow comes as a thin layer on top of [Terraform](https://www.terraform.io/), [Packer](https://www.packer.io/), [Ansible](https://www.ansible.com/) and [kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm). Following this approach we aim to provide a simple, light-weight, tool for kubernetes provisioning, while making DevOps transparent and fun. 

## Architecture
Deploying a KubeNow cluster you will get:

 - A Kubernetes cluster up and running in less than 5 minutes (provisioned with [kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm/))
 - [Weave](https://www.weave.works/) networking
 - [Traefik](https://traefik.io/) HTTP reverse proxy and load balancer
 - [Kubernetes Dashboard](http://kubernetes.io/docs/user-guide/ui/)
 - Cloudflare dynamic DNS integration

