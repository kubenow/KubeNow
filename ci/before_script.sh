#!/bin/bash

# Render Terraform configuration
# Common
if [ "$HOST_CLOUD" = 'openstack' ]; then
  cp terraform.tfvars.os-template terraform.tfvars
else
  cp "terraform.tfvars.${HOST_CLOUD}-template" terraform.tfvars
fi

mkdir -p "$HOME/.ssh/" && cp keypair/kubenow-ci.pub "$HOME/.ssh/id_rsa.pub"
sed -i -e "s/your-cluster-prefix/kubenow-ci-${TRAVIS_BUILD_NUMBER}-${HOST_CLOUD}/g" terraform.tfvars
sed -i -e "s/your-kubeadm-token/${CI_KUBETOKEN}/g" terraform.tfvars
sed -i -e 's/use_cloudflare = "false"/use_cloudflare = "true"/g' terraform.tfvars
sed -i -e "s/your-cloudflare-email/${CI_CLOUDFLARE_EMAIL}/g" terraform.tfvars
sed -i -e "s/your-cloudflare-token/${CI_CLOUDFLARE_TOKEN}/g" terraform.tfvars
sed -i -e "s/your-domain-name/${CI_CLOUDFLARE_DOMAIN}/g" terraform.tfvars

# AWS
sed -i -e "s/your-acces-key-id/${AWS_ACCESS_KEY_ID}/g" terraform.tfvars
sed -i -e "s#your-secret-access-key#${AWS_SECRET_ACCESS_KEY}#g" terraform.tfvars
# GCE
printf '%s\n' "$GCE_CREDENTIALS" > "$HOME/account_file.json"
sed -i -e "s/your_project_id/${GCE_PROJECT_ID}/g" terraform.tfvars
# OS
sed -i -e "s/your-pool-name/${OS_POOL_NAME}/g" terraform.tfvars
sed -i -e "s/external-net-uuid/${OS_EXTERNAL_NET_UUUID}/g" terraform.tfvars
sed -i -e "s/your-master-flavor/${OS_MASTER_FLAVOR}/g" terraform.tfvars
sed -i -e "s/your-node-flavor/${OS_NODE_FLAVOR}/g" terraform.tfvars
sed -i -e "s/your-edge-flavor/${OS_EDGE_FLAVOR}/g" terraform.tfvars

# Check code quality
# check Terraform
terraform fmt common/cloudflare
terraform fmt common/inventory
terraform fmt "$HOST_CLOUD"
git diff --exit-code # this will fail if terraform changed something
# check Ansible
# skip ANSIBLE0006: avoid using curl
# skip ANSIBLE0012: missing change_when on command/shell etc.
ansible-lint -x ANSIBLE0006,ANSIBLE0012 playbooks/*.yml
# check Shell
shellcheck "$(find . -type f -name '*.sh')"
