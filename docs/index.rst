Welcome to KubeNow's documentation!
===================================
Welcome to KubeNow's documentation! This is a place where we aim to help you to provision Kubernetes, the KubeNow's way. If you are new to Kubernetes, and to cloud computing, this is going to take a while to grasp the first time. Luckily, once you get the procedure, it's going to be very quick to spawn your clusters.

Getting Started
===============

Step 0: Prerequisites
^^^^^^^^^^^^^^^^^^^^^

Install provisioning tools
""""""""""""""""""""""""""

There are 3 tools that you need to install on your local machine, in order to provision Kubernetes with KubeNow:

- `Packer <http://packer.io/>`_ to build a KubeNow cloud image on the host cloud
- `Terraform <http://terraform.io/>`_ to fire-up the virtual infrastructure on the host cloud
- `Ansible <http://ansible.io/>`_ to provision the VMs (e.g. install and configure networking, reverse proxy etc.)

Get KubeNow
"""""""""""

To get KubeNow please clone its repository::

  git clone https://github.com/mcapuccini/KubeNow.git
  cd KubeNow

We assume that all of the commands in this wiki are being run in the KubeNow directory.

Step 1: Bootstrap Kubernetes on a host cloud
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This step depends on the cloud provider that your are going to use. Here you find a tutorial for each of the supported providers:

.. toctree::
   :maxdepth: 2

   OpenStack
