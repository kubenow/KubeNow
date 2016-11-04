FROM alpine:3.3

RUN apk update

# Add apk deps
RUN apk add --no-cache \
  curl \
  build-base \
  python \
  python-dev \
  libffi-dev \
  openssl-dev

# Add deps by HashiCorp
RUN curl \
  https://releases.hashicorp.com/packer/0.11.0/packer_0.11.0_linux_amd64.zip \
  > /tmp/packer.zip
RUN curl \
  https://releases.hashicorp.com/terraform/0.7.8/terraform_0.7.8_linux_amd64.zip \
  > /tmp/terraform.zip
RUN unzip /tmp/packer.zip -d /usr/bin
RUN unzip /tmp/terraform.zip -d /usr/bin
RUN chmod +x /usr/bin/packer
RUN chmod +x /usr/bin/terraform
RUN rm /tmp/packer.zip
RUN rm /tmp/terraform.zip

# Add Ansible
RUN wget \
  https://bootstrap.pypa.io/get-pip.py \
  -O /tmp/get-pip.py
RUN python /tmp/get-pip.py
RUN pip install --upgrade pip
RUN pip install ansible==2.1.2.0
RUN rm /tmp/get-pip.py

# Make work dir
RUN mkdir /work
WORKDIR /work
