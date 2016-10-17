# Cheese deployment
In this guide we are going to deploy a simple application: [cheese-deployent](https://github.com/mcapuccini/KubeNow/blob/master/examples/cheese-deployment.yml). This deployment defines 3 services with a 2 replication factor. Traefik will load balance the requests among the replicas in the Kubernetes nodes. For more details about the cheese deployment, please refer to: [https://docs.traefik.io/user-guide/kubernetes](https://docs.traefik.io/user-guide/kubernetes/).

Start by copying the [cheese-deployent.yml](https://github.com/mcapuccini/KubeNow/blob/master/examples/cheese-deployment.yml) file into the master node. If you configured [CloudFlare](https://github.com/mcapuccini/KubeNow/wiki#step-3-configure-dns-records), your master node will have a domain name in such form: `cluster_prefix-master.somedomain.com` (**n.b.** here we assume that `somedomain.com` contains any subdomain you might have set when configuring CloudFlare). 

```bash
scp examples/cheese-deployment.yml ubuntu@cluster_prefix-master.somedomain.com:/home/ubuntu
``` 

Now please ssh into the master, and substitute `yourdomain.com` with `somedomain.com` in `cheese-deployent.yml`: 

```bash
ssh ubuntu@cluster_prefix-master.somedomain.com
sed -i 's/yourdomain.com/somedomain.com/g' cheese-deployment.yml
``` 

Finally, deploy the application using [kubectl](http://kubernetes.io/docs/user-guide/kubectl-overview/):

```bash
kubectl apply -f cheese-deployment.yml
```

If everything goes well you should see some front-ends and back-ends showing up in the [Traefik UI](https://github.com/mcapuccini/KubeNow/wiki/Access-the-Dashboard-and-the-Traefik-UIs#create-ssh-tunnels), and you should be able to access the services at:
 
- http://stilton.somedomain.com
- http://cheddar.somedomain.com
- http://wensleydale.somedomain.com