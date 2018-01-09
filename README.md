## Setting up an openshift cluster with KubeNow

Install kn client:

```bash
curl -f "https://raw.githubusercontent.com/kubenow/KubeNow/feature/openrisknet/bin/kn" -o "/tmp/kn"
sudo mv /tmp/kn /usr/local/bin/
sudo chmod +x /usr/local/bin/kn
```

Create bastion:

```bash
# init bastion terraform configuration directory
kn init-os openstack my-orn-bastion
cd my-orn-bastion

# source your openstack-rc-credentials file
source /path/to/openstack/credentials

# Now edit parameters in terraform.tfvars.bastion
# You can find your network name with command:
#
# kn openstack network list --external
#
# rename template
mv terraform.tfvars.openstack.bastion-template terraform.tfvars

# edit config
vim terraform.tfvars

# now create bastion host:
kn apply
```

Log in to Bastion host and create cluster:

```bash
kn ssh

# swich into root user on bastion
sudo su

# if bastion is using selinux disable it when running docker
setenforce 0

# init cluster configuration directory on bastion (kn is already installed on "orn-os-3"-image)
kn init-os openstack my-orn
cd my-orn

# source your openstack-rc-credentials file
# (you first need to copy file to bastion, probably easiest by pasting it into vi)
# e.g. vi my-openstack.rc
source my-openstack.rc

# Now edit parameters in terraform.tfvars.standard
#
vi terraform.tfvars.standard

# then rename it
mv terraform.tfvars.standard terraform.tfvars

# now create bastion host:
kn apply
```

Deploy openshift on cluster:

```bash
# Clone and checkout openshift-ansible repo
kn git clone https://github.com/openshift/openshift-ansible.git
kn git -C openshift-ansible checkout release-3.6

# Run ansible-playbook
kn ansible-playbook openshift-ansible/playbooks/byo/config.yml
```

