Install core components
=======================
At this point you should have a core Kubernetes cluster up and running, on your cloud provider. The Kubernetes cluster that you deploy in the previous step is not ready to use, as it lacks the overlay network service that will allow your containers to communicate. KubeNow comes with an `install-core.yml <https://github.com/kubenow/KubeNow/blob/master/playbooks/install-core.yml>`_ playbook that installs the overlay network along with some other useful components.

The core components include:

- `Weave <http://weave.works>`_ overlay network (tag: `minimal`)
- `Traefik <http://traefik.io/>`_ HTTP reverse proxy and load balancer (**only on the edge nodes**, tag: ``traefik``)
- `Cloudflare <http://cloudflare.com>`_ Cloudflare dynamic DNS configuration (tag: ``cloudflare``)
- `GlusterFS <https://www.gluster.org/>`_ GlusterFS distributed files system (**on every node but the master and the edge**, tag: ``glusterfs``).

  - The playbook also configures a `persistent volume <https://kubernetes.io/docs/user-guide/persistent-volumes/>`_ called ``shared-volume`` that points to the GlusterFS endpoints.

**Pro tip:** you can use the tags to install or skip certain components while running `install-core.yml <https://github.com/kubenow/KubeNow/blob/master/playbooks/install-core.yml>`_. For more informations please refer to the `Ansible tags documentation <http://docs.ansible.com/ansible/playbooks_tags.html>`_.

.. image:: ../../img/architecture.png

This kind of deployment is particularly convenient, as only the master node, and the edge nodes (that run `Traefik <https://traefik.io/>`_) need to be associated to public IPs (which can be scarce). Therefore, the end user will access the microservices running in the Kubernetes nodes, through an edge node that will act as a reverse proxy. The `Cloudflare <http://cloudflare.com>`_ service will loadbalance the requests over the edge nodes.

Cloudflare account configuration
--------------------------------
In this stack, the edge nodes act as getaways to access some services running in the Kubernetes nodes. Typically, you want the end user to access your services through a domain name. One option is to manually configure the DNS services, for a domain name, to load balance the requests among the edge nodes. However, doing this for each deployment can be tedious, and prone to configuration errors. Hence, we recommend to sign up for a free account on `Cloudflare <http://cloudflare.com>`_, that you can use as dynamic DNS service for your domain name.

Once you have your Cloudflare account, start by creating a ``playbooks/roles/cloudflare/vars/conf.yml`` configuration file. There is a template file that you can use for your convenience::

  mv playbooks/roles/cloudflare/vars/conf.yml.template playbooks/roles/cloudflare/vars/conf.yml

In this configuration file you need to set:

- **cf_mail**: the mail that you used to register your Cloudflare account
- **cf_token**: an authentication token that you can generate from the Cloudflare web interface
- **cf_zone**: a zone that you created in your Cloudflare account. This typically matches your domain name (e.g. somedomain.com)
- **cf_subdomain** (optional): you can set a subdomain name for this cluster, if you don't want to use the whole domain for this purpose

Deploy the stack
----------------
Once you are done with the Cloudflare account configuration, you can deploy the stack via `Ansible <http://ansible.com>`_::

  ansible-playbook playbooks/install-core.yml

To make sure that each service is running you can run the following command::

  ansible-playbook playbooks/infra-test.yml
