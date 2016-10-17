The [dashboard UI](http://kubernetes.io/docs/user-guide/ui/) runs on port 8001 in the master node, and the [Trafik](https://traefik.io/) UI runs on port 8080 of each edge node. For security reasons, we discourage you to open such ports in your cloud provider, to directly access the UIs. 

# Accessing the UI through ssh tunnelling

## Create SSH tunnels
To securely access the UIs you can set up ssh tunnelling, running an [Ansible](https://www.ansible.com/) playbook:

```bash
ansible-playbook playbooks/ui-tunnels-add.yml
```

If everything goes well, you should be able to access the UIs at:

- **Kubernetes Dashboard**: [http://localhost:8001/ui](http://localhost:8001/ui)
- **Traefik Dashboard for edge node 00**: [http://localhost:9000](http://localhost:9000)
- **Traefik Dashboard for edge node 01**: [http://localhost:9001](http://localhost:9001)
- **Traefik Dashboard for edge node XX**: http://localhost:90XX

Keep in mind that when you reboot your workstation you will need to recreate the tunnels.

## Change default ports

If the previous ports are not free on your working station you can change them by setting `dashboard_port` and `traefik_port_base`. For instance you could run:

 ```bash
ansible-playbook -e "dashboard_port=6001" -e "traefik_port_base=70" playbooks/ui-tunnels-add.yml
```

The previous command will forward the UIs to your workstation as follows:

- **Kubernetes Dashboard**: [http://localhost:6001/ui](http://localhost:6001/ui)
- **Traefik Dashboard for edge node 00**: [http://localhost:7000](http://localhost:7000)
- **Traefik Dashboard for edge node 01**: [http://localhost:7001](http://localhost:7001)
- **Traefik Dashboard for edge node XX**: http://localhost:70XX

## Delete SSH tunnels

To delete the ssh tunnels you can run this playbook:

```bash
ansible-playbook playbooks/ui-tunnels-rm.yml
```

If you are not running the tunnels on the default ports, you need to specify them as in the following example:

```bash
ansible-playbook -e "dashboard_port=6001" -e "traefik_port_base=70" playbooks/ui-tunnels-rm.yml
```

**N.B.** If you destroy and recreate the cluster before you run this, the informations about the previous deployment will be overwritten, and you will have to delete the SSH tunnels manually.