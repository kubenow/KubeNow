# KubeNow

Using KubeNow you can rapidly deploy, scale, and tear down your Kubernetes clusters on any cloud. 

## Approach
Rather than providing an all-in-one tool for provisioning a Kubernetes cluster (e.g. [Juju](https://jujucharms.com/) and [Kubespray](https://github.com/kubespray/kargo-cli)), KubeNow comes as a thin layer on top of [Terraform](https://www.terraform.io/), [Packer](https://www.packer.io/), [Ansible](https://www.ansible.com/) and [kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm). Following this approach we aim to provide a simple, light-weight, tool for Kubernetes provisioning, while making DevOps transparent and fun. 

## Architecture
Deploying a KubeNow cluster you will get:

 - A Kubernetes cluster up and running in less than 5 minutes (provisioned with [kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm/))
 - [Weave](https://www.weave.works/) networking
 - [Traefik](https://traefik.io/) HTTP reverse proxy and load balancer
 - [Kubernetes Dashboard](http://kubernetes.io/docs/user-guide/ui/)
 - [Cloudflare](https://www.cloudflare.com/) dynamic DNS integration

![GitHub Logo](/architecture.png)

This kind of deployment is particularly convenient, as only the master node, and the **edge nodes** (that run [Traefik](https://traefik.io/)) need to be associated to public IPs (which are usually scarce). Therefore, the end user will access the microservices running in the **Kubernetes nodes**, through a **edge node** that will act as a reverse proxy. The DNS service will loadbalance the requests over the edge nodes. 

## Getting started

Want to try KubeNow? You can get started following the tutorials in the [wiki](https://github.com/mcapuccini/KubeNow/wiki).

## Roadmap

### Core
- [x] Kubernetes 
- [x] Kubernetes Dashboard
- [ ] High Availability
- [ ] Scaling 
- [ ] Autoscaling

### Cloud Providers
- [x] OpenStack
- [ ] Google Cloud Platform
- [ ] Amazon Web Services
- [ ] Local 


### Load balancer
- [x] Traefik

### Networking
- [x] Weave
- [ ] Callico

### Big Data Frameworks
- [ ] Spark
- [ ] Hadoop
