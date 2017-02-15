Bootstrap Kubernetes on a host cloud
====================================

This step is slightly different for each host cloud. Here you find a section for each of the supported providers.

.. contents:: Sections
  :depth: 2

Bootstrap on OpenStack
----------------------

Prerequisites
~~~~~~~~~~~~~

In this section we assume that:

- You have downloaded and sourced the OpenStack RC file for your tenancy: ``source project-openrc.sh``

Every OpenStack installation it's a bit different, and the RC file you get to download from the interface might be incomplete. Please make sure that all of these environment variables are set in the RC file::

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

- You have a floating IP quota that allows to allocate a public IP for each master and edge node (at least 2 in total)
- You installed the glance command-line client in your local machine: http://docs.openstack.org/user-guide/common/cli-install-openstack-command-line-clients.html

Import the KubeNow image (only the first time you are deploying)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The first time you are going to deploy KubeNow, you'll have to import its cloud image. This considerably speeds up the following bootstraps, as all of the required software will already be installed on the instances.

You can import the latest image build by running the following `Ansible <http://ansible.com>`_ playbook::

  ansible-playbook playbooks/import-openstack-image.yml

If everything goes well, you will see the new image in the OpenStack web interface (Compute > Images). As an alternative, you can check that the image is present using the OpenStack command line client::

  glance image-list

Bootstrap Kubernetes
~~~~~~~~~~~~~~~~~~~~

Now we are going to provision the required virtual infrastructure in OpenStack using Terraform. This procedure will inject enough information in each instance, to independently provision itself.

Start by creating a ``terraform.tfvars`` file. There is a template that you can use for your convenience: ``mv terraform.tfvars.os-template terraform.tfvars``. In this configuration file you will need to set:

**Cluster configuration**

- **cluster_prefix**: every resource in your tenancy will be named with this prefix
- **KuberNow_image**: name of the image that you previously created using Packer
- **ssh_key**: path to your public ssh-key to be used (for ssh node access)
- **floating_ip_pool**: a floating IP pool name
- **external_network_uuid**: the uuid of the external network in the OpenStack tenancy
- **dns_nameservers**: (optional, only needed if you want to use other dns-servers than default 8.8.8.8 and 8.8.4.4)
- **kubeadm_token**: a token that will be used by kubeadm, to bootstrap Kubernetes. You can run generate_kubetoken.sh to create a valid one.

**Master configuration**

- **master_flavor**: an instance flavor for the master

**Node configuration**

- **node_count**: number of Kubernetes nodes to be created (no floating IP is needed for these nodes)
- **node_flavor**: an instance flavor name for the Kubernetes nodes
- **node_flavor_id**: this is an alternative way of specifying the instance flavor (optional, please set this only if **node_flavor** is empty)

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

Good! Now you have a minimal Kubernetes cluster up and running, and you are ready to :doc:`install the KubeNow core components <install-core>`.


Bootstrap on Google Cloud (GCE)
-------------------------------

Prerequisites
~~~~~~~~~~~~~

In this section we assume that:

- You have enabled the Google Compute Engine API: API Manager > Library > Compute Engine API > Enable
- You have created and downloaded a service account file for your GCE project: Api manager > Credentials > Create credentials > Service account key

Import the KubeNow image (only the first time you are deploying)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The first time you are going to deploy KubeNow, you'll have to import its cloud image. This considerably speeds up the following bootstraps, as all of the required software will already be installed on the instances.

You can import the latest image build by running the following `Ansible <http://ansible.com>`_ playbook::

  ansible-playbook -e "credentials_file_path=/full/path/to/service_account.json" playbooks/import-gce-image.yml

If everything goes well, you will see the new image in the GCE web interface (Compute Engine > Images). As an alternative, you can check that the image is present using the Google Cloud command line client::

  gcloud compute images list

Bootstrap Kubernetes
~~~~~~~~~~~~~~~~~~~~

Now we are going to provision the required virtual infrastructure in Google Cloud using Terraform. This procedure will inject enough information in each instance, to independently provision itself.

Start by creating a ``terraform.tfvars`` file. There is a template that you can use for your convenience: ``mv terraform.tfvars.gce-template terraform.tfvars``. In this configuration file you will need to set:

**Cluster configuration**

- **cluster_prefix**: every resource in your project will be named with this prefix (the name must match ``(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)``, e.g. "kubenow-image")
- **KuberNow_image**: name of the image that you previously created using Packer
- **kubeadm_token**: a token that will be used by kubeadm, to bootstrap Kubernetes. You can run `generate_kubetoken.sh` to create a valid one.
- **ssh_key**: path to your public ssh-key to be used (for ssh node access)

**Google credentials**

- **gce_credentials_file**: path to your service account file
- **gce_region**: the zone for your project (e.g. ``europe-west1-b``)
- **gce_project**: your project id

**Master configuration**

- **master_flavor**: an instance flavor for the master (e.g. ``n1-standard-1``)
- **master_disk_size**: master disk size in GB

**Node configuration**

- **node_count**: number of Kubernetes nodes to be created
- **node_flavor**: an instance flavor for the Kubernetes nodes (e.g. ``n1-standard-1``)
- **node_disk_size**: nodes disk size in GB

**Edge configuration**

- **edge_count**: number of egde nodes to be created
- **edge_flavor**: an instance flavor for the edge nodes (e.g. ``n1-standard-1``)
- **edge_disk_size**: edges disk size in GB

Once you are done with your settings you are ready to bootstrap the cluster using Terraform::

  terraform get gce # get required modules (only the first time you deploy)
  terraform apply gce # deploy the cluster

If everything goes well, something like the following message will be printed::

  Apply complete! Resources: X added, 0 changed, 0 destroyed.

To verify that each node connected to the master you can run::

  ansible master -a "kubectl get nodes"

If all of the nodes are not yet connected and in the Ready state, wait a minute and try again. Keep in mind that booting the instances takes a couple of minutes.

Good! Now you have a minimal Kubernetes cluster up and running, and you are ready to :doc:`install the KubeNow core components <install-core>`.

Bootstrap on Amazon Web Services (EC2)
--------------------------------------

Prerequisites
~~~~~~~~~~~~~

In this section we assume that:

- You have an IAM user along with its *access key* and *security credentials* (http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)

Bootstrap Kubernetes
~~~~~~~~~~~~~~~~~~~~

Now we are going to provision the required virtual infrastructure in AWS (Amazon Web Services) using Terraform. This procedure will inject enough information in each instance, to independently provision itself.

Start by creating a ``terraform.tfvars`` file. There is a template that you can use for your convenience: ``mv terraform.tfvars.aws-template terraform.tfvars``. In this configuration file you will need to set:

**Cluster configuration**

- **cluster_prefix**: every resource in your tenancy will be named with this prefix
- **kubenow_image_id**, it can be one of these: ``ami-6b427518`` (region: ``eu-west-1``), ``ami-e516de8a`` (region: ``eu-central-1``), ``ami-32647156`` (region: ``eu-west-2``), ``ami-3b60a12d`` (region: ``us-east-1``), ``ami-e31b3e86`` (region: ``us-east-2``), ``ami-78732f18`` (region: ``us-west-1``), ``ami-830386e3`` (region: ``us-west-2``), ``ami-b2aa17d6`` (region: ``ca-central-1``)

  + **Warning:** choose the image according to the region you want to use

- **kubeadm_token**: a token that will be used by kubeadm, to bootstrap Kubernetes. You can run `generate_kubetoken.sh` to create a valid one.
- **ssh_key**: path to your public ssh-key to be used for ssh node access (e.g. ``~/.ssh/id_rsa.pub``)
- **aws_region**: the region where your cluster will be bootstrapped (e.g. ``eu-west-1``)

  + **Warning:** the image that you previously selected has to be available in this region
  
- **availability_zone**: an availability zone for your cluster (e.g. ``eu-west-1a``)

**Credentials**

- **aws_access_key_id**: your access key id
- **aws_secret_access_key**: your secret access key

**Master configuration**

- **master_instance_type**: an instance type for the master (e.g. ``t2.medium``)
- **master_disk_size**: edges disk size in GB

**Node configuration**

- **node_count**: number of Kubernetes nodes to be created
- **node_instance_type**: an instance type for the Kubernetes nodes (e.g. ``t2.medium``)
- **node_disk_size**: edges disk size in GB

**Edge configuration**

- **edge_count**: number of egde nodes to be created
- **edge_instance_type**: an instance type for the edge nodes (e.g. ``t2.medium``)
- **edge_disk_size**: edges disk size in GB

Once you are done with your settings you are ready to bootstrap the cluster using Terraform::

  terraform get aws # get required modules (only the first time you deploy)
  terraform apply aws # deploy the cluster

If everything goes well, something like the following message will be printed::


  Apply complete! Resources: X added, 0 changed, 0 destroyed.


To verify that each node connected to the master you can run::

  ansible master -a "kubectl get nodes"

If all of the nodes are not yet connected and in the Ready state, wait a minute and try again. Keep in mind that booting the instances takes a couple of minutes. **Warning** if you are using the free tier, the cluster will take a little bit more to bootstrap (~5 minutes).

Good! Now you have a minimal Kubernetes cluster up and running, and you are ready to :doc:`install the KubeNow core components <install-core>`.
