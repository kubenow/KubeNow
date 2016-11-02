Clean after yourself
--------------------

Cloud resources are typically pay-per-use, hence it is good to release them when they are not used. Here we show how to destroy a KubeNow cluster.

To release the resources, please run::

  terraform destroy <cloud-provider>

``<cloud-provider>`` can be "openstack" or "gce".

To delete the Clouflare DNS records, please run::

  ansible-playbook playbooks/clean-cloudflare.yml

**Warinig:** if you create a new cluster before deleting the DNS records, the Ansible inventory will be replaced and you will have to delete the records manually.
