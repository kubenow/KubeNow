![architecture](img/logo_wide_50dpi.png)

[![Documentation Status](https://readthedocs.org/projects/kubenow/badge/?version=stable)](http://kubenow.readthedocs.io/en/stable/?badge=stable)
[![Documentation Status](https://readthedocs.org/projects/kubenow/badge/?version=latest)](http://kubenow.readthedocs.io/en/latest/?badge=latest)
[![Build Status](https://travis-ci.org/kubenow/KubeNow.svg?branch=master)](https://travis-ci.org/kubenow/KubeNow)

KubeNow is a cloud agnostic platform for microservices, based on Docker and Kubernetes. Other than lighting-fast Kubernetes operations, KubeNow helps you in lifting your final application configuring DNS records and distributed storage. Once you have defined your application as a Helm package, you can lift it running 3 commands:

```bash
kn init my-awesome-deployment
kn apply <aws|gce|openstack>
kn helm install my-app-package
```

:warning: *kn* CLI is not documented yet.

## Table of Contents

- [Architecture](#architecture)
- [Manifesto](#manifesto)
- [Getting Started](#getting-started)
- [Roadmap](#roadmap)

## Architecture
Deploying a KubeNow cluster you will get:

 - A Kubernetes cluster up and running in ~10 minutes (provisioned with [kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm/))
 - [Weave](https://www.weave.works/) networking
 - [Traefik](https://traefik.io/) HTTP reverse proxy and load balancer
 - [Cloudflare](https://www.cloudflare.com/) dynamic DNS configuration
 - [GlusterFS](https://www.gluster.org/) distributed file system

![architecture](img/architecture.png)

In a KubeNow cluster there are 3 instance types:

- **master**: it runs the Kubernetes master, and it optionally acts as an ingress controller proxying from the Internet to the application services through its public IP.
- **node**: it runs a Kubernetes node and it hosts application services.
- **edge**: it is a specialized kind of node with a public IP associated, it acts as an ingress controller proxying from the Internet to the application services. It can run application services as well. Edge nodes are optional.
- **glusternode**: it is a specialized kind of node that runs only a GlusterFS server. One or more *glusternodes* can be used to provide distributed storage for the application services. Glusternodes are optional.

**Cloudflare** can be optionally used to setup DNS records and SSL/TSL (HTTPS) encryption.

## Manifesto

- We want fast deployments: each instance provision itself independently and immutable images are used
- We use existing provisioning tools: [Terraform](https://www.terraform.io/), [Packer](https://www.packer.io/), [Ansible](https://www.ansible.com/) and [kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm)
- We avoid resources that are available only for a specific cloud provider
- We provision IaaS, PaaS and SaaS: lifting a distributed application should be possible with a few commands

## Getting started

Want to try KubeNow? You can get started following the tutorials in the documentation:

[![Documentation Status](https://readthedocs.org/projects/kubenow/badge/?version=stable)](http://kubenow.readthedocs.io/en/stable/?badge=stable)
[![Documentation Status](https://readthedocs.org/projects/kubenow/badge/?version=latest)](http://kubenow.readthedocs.io/en/latest/?badge=latest)

## Roadmap

### Core
- [x] Kubernetes
- [ ] High Availability
- [ ] Scaling (it lacks documentation, but it should work)
- [ ] Autoscaling
- [ ] Dashboard

### Cloud Providers
- [x] OpenStack
- [x] Google Cloud Platform
- [x] Amazon Web Services
- [ ] Local
- [ ] Bare Metal

### Load balancer
- [x] Traefik

### Networking
- [x] Weave

### Big Data Frameworks
- [ ] Spark

### Storage
- [x] GlusterFS

### SSL/TSL (HTTPS)
- [x] Cloudflare
- [ ] Let's Encrypt
