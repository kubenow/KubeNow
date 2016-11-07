#!/bin/bash

# Add deps
sudo apt-get install -y \
  curl \
  build-base \
  python \
  python-dev \
  libffi-dev \
  openssl-dev

# Add deps by HashiCorp
curl \
  https://releases.hashicorp.com/packer/0.11.0/packer_0.11.0_linux_amd64.zip \
  > /tmp/packer.zip
curl \
  https://releases.hashicorp.com/terraform/0.7.8/terraform_0.7.8_linux_amd64.zip \
  > /tmp/terraform.zip
unzip /tmp/packer.zip -d /usr/bin
unzip /tmp/terraform.zip -d /usr/bin
chmod +x /usr/bin/packer
chmod +x /usr/bin/terraform

# Add Ansible
curl \
  https://bootstrap.pypa.io/get-pip.py \
  > /tmp/get-pip.py
python /tmp/get-pip.py
pip install --upgrade pip
pip install ansible==2.2.0.0
