# Clean after yourself
Cloud resources are typically pay-per-use, hence it is good to release them when they are not used. Here we show how to destroy a KubeNow cluster. 

## Destroy the cluster with terraform
To destroy the cluster on the host cloud, and release all of the resources, please run:

```bash
terraform destroy
```

## Remove CloudFlare records
To remove the DNS records form your [CloudFlare](https://www.cloudflare.com/) account, please run:

```bash
ansible-playbook playbooks/cloudflare-rm.yml
```

**N.B.** If you create a new cluster before you run this, the informations about the previous deployment will be overwritten, and you will have to remove the DNS records manually.

## Remove known hosts fingerprints
In order to avoid tedious SSH errors when the public IPs will be reused by other VMs, you can remove the known host fingerprints for the instances you just destroyed. To do so, please run:

```bash
ansible-playbook playbooks/knownhosts-rm.yml
```

**N.B.** If you create a new cluster before you run this, the informations about the previous deployment will be overwritten, and you will have to remove the known hosts fingerprints manually.