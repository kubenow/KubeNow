Deploy traefik-lb stack
=======================
At this point you should have a core Kubernetes cluster up and running, on your cloud provider. KubeNow comes with some predefined software stacks that you can deploy on top of Kubernetes. If you are doing your first steps with Kubernetes, we recommend to start by deploying the traefik-lb stack, which is a good basis for many use cases.

The the traefik-lb stack include:

- `Weave <http://weave.works>`_ networking installation
- `Traefik <http://traefik.io/>`_ HTTP reverse proxy and load balancer installation (**only on the edge nodes**)
- `CloudFlare <http://cloudflare.com>`_ CloudFlare dynamic DNS configuration

.. image:: https://github.com/mcapuccini/KubeNow/raw/master/architecture.png

This kind of deployment is particularly convenient, as only the master node, and the edge nodes (that run `Traefik <https://traefik.io/>`_) need to be associated to public IPs (which can be scarce). Therefore, the end user will access the microservices running in the Kubernetes nodes, through a edge node that will act as a reverse proxy. The `CloudFlare <http://cloudflare.com>`_ service will loadbalance the requests over the edge nodes.

CloudFlare account configuration
--------------------------------
In this stack, the edge nodes act as getaways to access some services running in the Kubernetes nodes. Typically, you want the end user to access your services through a domain name. One option is to manually configure the DNS services, for a domain name, to load balance the requests among the edge nodes. However, doing this for each deployment can be tedious, and and prone to configuration errors. Hence, we recommend to sign up for a free account on `CloudFlare <http://cloudflare.com>`_, that you can use as dynamic DNS service for your domain name.

Once you have your CloudFlare account, start by creating a ``stacks/traefik-lb/roles/cloudflare/vars/conf.yml`` configuration file. There is a template file that you can use for your convenience::

  mv stacks/traefik-lb/roles/cloudflare/vars/conf.yml.template stacks/traefik-lb/roles/cloudflare/vars/conf.yml

In this configuration file you need to set:

- **cf_mail**: the mail that you used to register your CloudFlare account
- **cf_token**: an authentication token that you can generate from the CloudFlare web interface
- **cf_zone**: a zone that you created in your CloudFlare account. This typically matches your domain name (e.g. somedomain.com)
- **cf_subdomain** (optional): you can set a subdomain name for this cluster, if you don't want to use the whole domain for this purpose

Deploy the stack
----------------
Once you are done with the CloudFlare account configuration, you can deploy the stack via `Ansible <http://ansible.com>`_::

  ansible-playbook stacks/traefik-lb/main.yml

To make sure that each service is running you can run the following command::

  ansible master -a "kubectl get pods --all-namespaces"
