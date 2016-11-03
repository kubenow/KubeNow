FROM alpine:3.3

RUN apk update

# Add build deps
RUN apk add --no-cache \
  curl

# Add KubeNow deps
RUN apk add --no-cache \
  git \
  python

# Add deps by HashiCorp
RUN curl \
  https://releases.hashicorp.com/packer/0.11.0/packer_0.11.0_linux_amd64.zip \
  > /tmp/packer.zip
RUN curl \
  https://releases.hashicorp.com/terraform/0.7.8/terraform_0.7.8_darwin_amd64.zip \
  > /tmp/terraform.zip
RUN unzip /tmp/packer.zip -d /usr/bin
RUN unzip /tmp/terraform.zip -d /usr/bin
RUN chmod +x /usr/bin/packer
RUN chmod +x /usr/bin/terraform
RUN rm /tmp/packer.zip
RUN rm /tmp/terraform.zip

# Add Ansible
RUN curl \
  http://releases.ansible.com/ansible/ansible-2.1.2.0.tar.gz \
  > /tmp/ansible.zip
RUN tar xzvf /tmp/ansible.zip -C /usr/local
RUN ln -s /usr/local/ansible-2.1.2.0/bin/* /usr/bin/
RUN rm /tmp/ansible.zip
