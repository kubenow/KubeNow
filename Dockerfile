FROM ubuntu:xenial-20171006
MAINTAINER "Marco Capuccini <marco.capuccini@it.uu.se>"

# Provisioners versions
ENV TERRAFORM_VERSION=0.10.7
ENV TERRAFORM_SHA256SUM=8fb5f587fcf67fd31d547ec53c31180e6ab9972e195905881d3dddb8038c5a37
ENV ANSIBLE_VERSION=2.3.1.0
ENV LIBCLOUD_VERSION=1.5.0
ENV J2CLI_VERSION=0.3.1.post0
ENV DNSPYTHON_VERSION=1.15.0
ENV JMESPATH_VERSION=0.9.3
ENV SHADE_VERSION=1.21.0
ENV OPENSTACKCLIENT_VERSION=3.11.0
# Terraform plugin versions
ENV PLUGIN_OPENSTACK=0.2.2
ENV PLUGIN_GOOGLE=0.1.3
ENV PLUGIN_AWS=1.0.0
ENV PLUGIN_AZURERM=0.2.2
ENV PLUGIN_NULL=1.0.0
ENV PLUGIN_CLOUDFLARE=0.1.0
ENV PLUGIN_TEMPLATE=1.0.0

# Install deps
RUN apt-get update -y && apt-get install -y \
  curl \
  apt-transport-https \
  git \
  curl \
  bc \
  jq \
  gosu \
  libffi-dev \
  openssl \
  unzip \
  python-pip \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PIP deps
RUN pip install \
  ansible=="$ANSIBLE_VERSION" \
  j2cli=="$J2CLI_VERSION" \
  dnspython=="$DNSPYTHON_VERSION" \
  jmespath=="$JMESPATH_VERSION" \
  apache-libcloud=="$LIBCLOUD_VERSION" \
  shade=="$SHADE_VERSION" \
  python-openstackclient=="$OPENSTACKCLIENT_VERSION"

# Install Terraform
RUN curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > \
    "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    echo "${TERRAFORM_SHA256SUM}  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > \
    "terraform_${TERRAFORM_VERSION}_SHA256SUMS" && \
    sha256sum -c "terraform_${TERRAFORM_VERSION}_SHA256SUMS" && \
    unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -d /bin && \
    rm -f "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Install Terraform plugins that are used
RUN mkdir -p /terraform_plugins
RUN curl "https://releases.hashicorp.com/terraform-provider-openstack/${PLUGIN_OPENSTACK}/terraform-provider-openstack_${PLUGIN_OPENSTACK}_linux_amd64.zip" > \
    "terraform-provider-openstack_${PLUGIN_OPENSTACK}_linux_amd64.zip" && \
    unzip "terraform-provider-openstack_${PLUGIN_OPENSTACK}_linux_amd64.zip" -d /terraform_plugins/ && \
    rm -f "terraform-provider-openstack_${PLUGIN_OPENSTACK}_linux_amd64.zip"

RUN curl "https://releases.hashicorp.com/terraform-provider-google/${PLUGIN_GOOGLE}/terraform-provider-google_${PLUGIN_GOOGLE}_linux_amd64.zip" > \
    "terraform-provider-google${PLUGIN_GOOGLE}_linux_amd64.zip" && \
    unzip "terraform-provider-google${PLUGIN_GOOGLE}_linux_amd64.zip" -d /terraform_plugins/ && \
    rm -f "terraform-provider-google${PLUGIN_GOOGLE}_linux_amd64.zip"

RUN curl "https://releases.hashicorp.com/terraform-provider-aws/${PLUGIN_AWS}/terraform-provider-aws_${PLUGIN_AWS}_linux_amd64.zip" > \
    "terraform-provider-aws_${PLUGIN_AWS}_linux_amd64.zip" && \
    unzip "terraform-provider-aws_${PLUGIN_AWS}_linux_amd64.zip" -d /terraform_plugins/ && \
    rm -f "terraform-provider-aws_${PLUGIN_AWS}_linux_amd64.zip"

RUN curl "https://releases.hashicorp.com/terraform-provider-azurerm/${PLUGIN_AZURERM}/terraform-provider-azurerm_${PLUGIN_AZURERM}_linux_amd64.zip" > \
    "terraform-provider-azurerm_${PLUGIN_AZURERM}_linux_amd64.zip" && \
    unzip "terraform-provider-azurerm_${PLUGIN_AZURERM}_linux_amd64.zip" -d /terraform_plugins/ && \
    rm -f "terraform-provider-azurerm_${PLUGIN_AZURERM}_linux_amd64.zip"

RUN curl "https://releases.hashicorp.com/terraform-provider-null/${PLUGIN_NULL}/terraform-provider-null_${PLUGIN_NULL}_linux_amd64.zip" > \
    "terraform-provider-null_${PLUGIN_NULL}_linux_amd64.zip" && \
    unzip "terraform-provider-null_${PLUGIN_NULL}_linux_amd64.zip" -d /terraform_plugins/ && \
    rm -f "terraform-provider-null_${PLUGIN_NULL}_linux_amd64.zip"

RUN curl "https://releases.hashicorp.com/terraform-provider-cloudflare/${PLUGIN_CLOUDFLARE}/terraform-provider-cloudflare_${PLUGIN_CLOUDFLARE}_linux_amd64.zip" > \
    "terraform-provider-cloudflare_${PLUGIN_CLOUDFLARE}_linux_amd64.zip" && \
    unzip "terraform-provider-cloudflare_${PLUGIN_CLOUDFLARE}_linux_amd64.zip" -d /terraform_plugins/ && \
    rm -f "terraform-provider-cloudflare_${PLUGIN_CLOUDFLARE}_linux_amd64.zip"

RUN curl "https://releases.hashicorp.com/terraform-provider-template/${PLUGIN_TEMPLATE}/terraform-provider-template_${PLUGIN_TEMPLATE}_linux_amd64.zip" > \
    "terraform-provider-template_${PLUGIN_TEMPLATE}_linux_amd64.zip" && \
    unzip "terraform-provider-template_${PLUGIN_TEMPLATE}_linux_amd64.zip" -d /terraform_plugins/ && \
    rm -f "terraform-provider-template_${PLUGIN_TEMPLATE}_linux_amd64.zip"

# Install Azure cli
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
    tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
RUN apt-get update -y && apt-get install -y azure-cli \
            && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add KubeNow
COPY . /opt/KubeNow

# Set entrypoint
ENTRYPOINT ["/opt/KubeNow/bin/docker-entrypoint"]
