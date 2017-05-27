#!/bin/bash

# Install Terraform
travis_retry curl \
  "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
  > /tmp/terraform.zip
sudo unzip /tmp/terraform.zip -d /usr/bin
sudo chmod +x /usr/bin/terraform

# Install Ansible and pip deps
sudo pip install --upgrade pip
sudo pip install \
  ansible=="${ANSIBLE_VERSION}" \
  j2cli \
  dnspython \
  jmespath \
  backports.ssl_match_hostname \
  apache-libcloud=="${LIBCLOUD_VERSION}" \
  shade \
  ansible-lint=="${ANSIBLE_LINT_VERSION}"
