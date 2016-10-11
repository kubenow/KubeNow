# KubeNow

Using KubeNow you can rapidly deploy, scale, and tear down your Kubernetes clusters on any cloud. 

## Approach
Rather than providing an all-in-one tool for provisioning a Kubernetes cluster (e.g. [Juju](https://jujucharms.com/) and [Kubespray](https://github.com/kubespray/kargo-cli)), KubeNow comes as a thin layer on top of [Terraform](https://www.terraform.io/), [Packer](https://www.packer.io/), [Ansible](https://www.ansible.com/) and [kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm). Following this approach we aim to provide a simple, light-weight, tool for kubernetes provisioning, while making DevOps transparent and fun. 
