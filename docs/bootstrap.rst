Bootstrap Kubernetes on a host cloud
====================================

This step depends on the cloud provider that your are going to use. Here you find a section for each of the supported providers.

.. contents:: Jump to your section of interest
  :depth: 2

Bootstrap on OpenStack
----------------------

Prerequisites
~~~~~~~~~~~~~

In this section we assume that:

- You have downloaded and sourced the OpenStack RC file for your tenancy: ``source project-openrc.sh``

Every OpenStack installation it's a bit different, and the RC file you get to download for the interface might be incomplete. Please make sure that all of these environment variables are set in the RC file::

  OS_USERNAME
  OS_PASSWORD
  OS_AUTH_URL
  OS_USER_DOMAIN_ID
  OS_DOMAIN_ID
  OS_REGION_NAME
  OS_PROJECT_ID
  OS_TENANT_ID
  OS_TENANT_NAME
  OS_AUTH_VERSION

- You added your workstation's public ssh key in your tenancy
- You created a private network to boot your cluster nodes on, with a router that connect's it to the external network
- You have a floating IP quota that allows to allocate a public IP for each master and edge node (at least 2 in total)
- You have a Ubuntu 16.04 (Xenial) image in your tenancy
- You set up the default security group to allow ingress traffic on port 80 and port 22

Some of this steps could be automated with Terraform, and we are thinking to do this in the future. However, some user may feel like having control over these steps, and we are looking forward to hear your opinion about that. Unfortunately, Terraform doesn't support conditional resource allocation yet, so we need to choose either an automatic or semi-automatic approach.

Build the KubeNow image (only the first time you are deploying)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The first time you are going to deploy KubeNow, you'll have to create its cloud image. This considerably speeds up the following bootstraps, as all of the required software will already be installed on the instances.

Start by creating a ``packer-conf.json`` file. There is a template that you can use for your convenience: ``mv packer-conf.json.template packer-conf.json``. In this configuration file you will need to set:

- **image_name**: the name of the image that will be created after the build (e.g. "KubeNow")
- **source_image_name**: a Ubuntu Xenial image, already present in your tenancy
- **network**: the ID of a private network, already present in your tenancy
- **flavor**: an instance flavor to use, in order to build the image
- **floating_ip_pool**: a floating IP pool

Once you are done with your settings you are ready to build KubeNow using Packer::

  packer build -var-file=packer-conf.json packer/build.json

If everything goes well, you will see the new image in the OpenStack web interface (Compute > Images). As an alternative, you can check that the image is present using the OpenStack command line client::

  nova image-list

Bootstrap Kubernetes
~~~~~~~~~~~~~~~~~~~~

Now we are going to provision the required virtual infrastructure in OpenStack using Terraform. This procedure will inject enough information in each instance, to independently provision itself.

Start by creating a ``terraform.tfvars`` file. There is a template that you can use for your convenience: ``mv terraform.tfvars.template terraform.tfvars``. In this configuration file you will need to set:

**Cluser configuration**

- **cluster_prefix**: every resource in your tenancy will be named with this prefix
- **KuberNow_image**: name of the image that you previously created using packer
- **keypair_name**: name of a keypair already present in your OpenStack project (for ssh node access)
- **private_network**: name of the network to fire up the instances on
- **floating_ip_pool**: a floating IP pool name
- **kubeadm_token**: a token that will be used by kubeadm, to bootstrap Kubernetes. You can run generate_kubetoken.sh to create a valid one.

**Master configuration**

- **master_flavor**: an instance flavor for the master

- **Node configuration**

- **node_count**: number of Kubernetes nodes to be created (no floating IP is needed for these nodes)
- **node_flavor**: an instance flavor for the Kubernetes nodes

**Edge configuration**

- **edge_count**: number of egde nodes to be created
- **edge_flavor**: an instance flavor for the edge nodes

Once you are done with your settings you are ready to bootstrap the cluster using Terraform::

  terraform get openstack # get required modules (only the first time you deploy)
  terraform apply openstack # deploy the cluster

If everything goes well, something like the following message will be printed::

  Apply complete! Resources: X added, 0 changed, 0 destroyed.

To verify that each node connected to the master you can run::

  ansible master -a "kubectl get nodes"

If all of the nodes are not yet connected and in the Ready state, wait a minute and try again. Keep in mind that booting the instances takes a couple of minutes.

Good! Now you have the core components of Kubernetes up and running, and you are ready to :doc:`deploy the traefik-lb stack <traefik-lb>`.
