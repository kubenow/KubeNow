Deploy your first application
=============================

In this guide we are going to deploy a simple application: `cheese-deployent <https://github.com/mcapuccini/KubeNow/blob/master/examples/cheese-deployment.yml>`_. This deployment defines 3 services with a 2 replication factor. Traefik will load balance the requests among the replicas in the Kubernetes nodes. For more details about the cheese deployment, please refer to: https://docs.traefik.io/user-guide/kubernetes.

Start by copying the cheese-deployent.yml file into the master node. If you configured CloudFlare, your master node will have a domain name in such form: cluster_prefix-master.somedomain.com (n.b. here we assume that somedomain.com contains any subdomain you might have set when configuring CloudFlare).

::

  scp examples/cheese-deployment.yml ubuntu@cluster_prefix-master.somedomain.com:/home/ubuntu

Now ssh into the master, and substitute ``domain_name`` with ``somedomain.com`` in `cheese-deployent.yml`::

  ssh ubuntu@cluster_prefix-master.somedomain.com
  sed -i 's/domain_name/somedomain.com/g' cheese-deployment.yml

Finally, deploy the application using kubectl::

  kubectl apply -f cheese-deployment.yml

If everything goes well you should see some front-ends and back-ends showing up in the Traefik UI, and you should be able to access the services at:

- http://stilton.somedomain.com
- http://cheddar.somedomain.com
- http://wensleydale.somedomain.com
