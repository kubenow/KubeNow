Here we list some logging/debugging tips that could help you fixing issues.

### Corrupted Terraform state
Terraform state files can get are out of synch with your infrastructure, and cause problems. A possible way to fix the issue is to destroy your nodes manually, and remove all state files and cached modules:

```bash
rm -R .terraform/ 
rm terraform.tfstate 
rm terraform.tfstate.backup 
```

### SSH connection errors
- Make sure to add your SSH key to your local keyring:

```bash
ssh-add private_key
```

- Make sure port 22 is allowed in your cloud provider security settings

If you still experience problems, checking out the console logs from your cloud provider could help.

### Console logs on OpenStack

Can't get the status from the nodes with `ansible master -a "kubectl get nodes"`? The nodes might not have started all right. Checking the console logs with [nova](http://docs.openstack.org/user-guide/common/cli-install-openstack-command-line-clients.html) could help:

_List node IDs and floating IPs:_
```bash
nova list
```

_Show console output from node of interest:_
```
nova console-log <node-id>
```

### Figure out hostnames and IP numbers
The bootstrap step should create an Ansible inventory list, which contains hostnames and IP addresses:

```bash
cat inventory
```

### Kubernetes Debug
Some frequently used commands to list the status and logs of kubernetes:

_List kubernetes pods_
```bash
# If you are logged into the node via SSH:
kubectl get pods --all-namespaces

# With Ansible from your local computer:
ansible master -a "kubectl get pods --all-namespaces"
```
_Describe status of a specific pod on your master node_
```bash
# If you are logged into the node via SSH:
kubectl describe pod <pod id> --all-namespaces

# With Ansible from your local computer:
ansible master -a "kubectl describe pod <pod id> --all-namespaces"
```
_Get the service log for kubernetes_
```bash
# If you are logged into the node via SSH:
sudo journalctl -r -u kubelet

#  With Ansible from your local computer:
ansible master -a "journalctl -r -u kubelet"
```

For a complete guide of kubectl: [http://kubernetes.io/docs/user-guide/kubectl-cheatsheet/](http://kubernetes.io/docs/user-guide/kubectl-cheatsheet/)
