#!/bin/bash

# AWS doesn't need image import
if [ "$HOST_CLOUD" = 'openstack' ] || [ "$HOST_CLOUD" = 'gce' ]; then
  ansible-playbook \
    -e "credentials_file_path=$HOME/account_file.json" \
    playbooks/import-"$HOST_CLOUD"-image.yml
fi

# Deploy KubeNow
terraform get "$HOST_CLOUD"
travis_retry terraform apply "$HOST_CLOUD"
ansible-playbook playbooks/install-core.yml
ansible-playbook playbooks/infra-test.yml
