Prerequisites
=============

Install provisioning tools
--------------------------

There are 3 tools that you need to install on your local machine, in order to provision Kubernetes with KubeNow:

- `Packer <http://packer.io/>`_ (0.12.3 or higher) to build a KubeNow cloud image on the host cloud
- `Terraform <http://terraform.io/>`_ (0.7.8 or higher) to fire-up the virtual infrastructure on the host cloud
- `Ansible <http://ansible.com/>`_ (2.2.0.0 or higher) to provision the VMs (e.g. install and configure networking, reverse proxy etc.)

Get KubeNow
-----------

KubeNow |release| is distributed via `GitHub <http://github.com>`_:

.. parsed-literal::

  git clone https://github.com/mcapuccini/KubeNow.git
  cd KubeNow
  git checkout |release|

All of the commands in this documentation are meant to be run in the KubeNow directory.
