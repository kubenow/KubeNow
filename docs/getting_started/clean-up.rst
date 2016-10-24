Clean after yourself
--------------------

Cloud resources are typically pay-per-use, hence it is good to release them when they are not used. Here we show how to destroy a KubeNow cluster.

To release the resources, please run::

  terraform destroy <cloud-provider>

``<cloud-provider>`` can be "openstack" or "gce".
