Deploy your first application
=============================

In this guide we are going to deploy a simple application: `cheese-deployent <https://github.com/mcapuccini/KubeNow/blob/master/examples/cheese-deployment.yml>`_. This deployment defines 3 services with a 2 replication factor. Traefik will load balance the requests among the replicas in the Kubernetes nodes. For more details about the cheese deployment, please refer to: https://docs.traefik.io/user-guide/kubernetes.

Start by substituting ``domain_name`` with ``yourdomain.com`` in ``cheese-deployent.yml`` (where `yourdomain.com` is the domain that points to the edge nodes, through CloudFlare)::

  sed -i -e 's/domain_name/yourdomain.com/g' examples/cheese-deployment.yml

Now, copy the ``cheese-deployent.yml`` file into the master node::

  ansible master -m copy -a "src=examples/cheese-deployment.yml dest=/home/ubuntu"

Finally, deploy the application using kubectl::

  ansible master -a "kubectl apply -f /home/ubuntu/cheese-deployment.yml"

If everything goes well you should see some front-ends and back-ends showing up in the Traefik UI, and you should be able to access the services at:

- http://stilton.yourdomain.com
- http://cheddar.yourdomain.com
- http://wensleydale.yourdomain.com
