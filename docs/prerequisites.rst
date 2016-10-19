Prerequisites
=============

Install provisioning tools
--------------------------

There are 3 tools that you need to install on your local machine, in order to provision Kubernetes with KubeNow:

- `Packer <http://packer.io/>`_ to build a KubeNow cloud image on the host cloud
- `Terraform <http://terraform.io/>`_ to fire-up the virtual infrastructure on the host cloud
- `Ansible <http://ansible.io/>`_ to provision the VMs (e.g. install and configure networking, reverse proxy etc.)

Get KubeNow
-----------

To get KubeNow please clone its repository:

.. parsed-literal::

  git clone https://github.com/mcapuccini/KubeNow.git
  git checkout |release|
  cd KubeNow

All of the commands in this documentation are meant to be run in the KubeNow directory.
