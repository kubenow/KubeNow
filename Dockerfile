FROM ubuntu:bionic-20181018

# Provisioners versions
ENV TERRAFORM_VERSION=0.10.7
ENV ANSIBLE_VERSION=2.4.2.0
ENV LIBCLOUD_VERSION=1.5.0
ENV J2CLI_VERSION=0.3.1.post0
ENV DNSPYTHON_VERSION=1.15.0
ENV JMESPATH_VERSION=0.9.3
ENV SHADE_VERSION=1.21.0
ENV OPENSTACKCLIENT_VERSION=3.16.1
ENV GLANCECLIENT_VERSION=2.8.0
ENV AWSCLI_VERSION=1.11.177
ENV AZURE_CLI_VERSION=2.0.25
ENV GOOGLE_CLOUD_SDK_VERSION=179.0.0-0
# Terraform plugin versions
ENV PLUGIN_OPENSTACK=0.2.2
ENV PLUGIN_GOOGLE=0.1.3
ENV PLUGIN_AWS=1.0.0
ENV PLUGIN_AZURERM=0.2.2
ENV PLUGIN_NULL=1.0.0
ENV PLUGIN_CLOUDFLARE=0.1.0
ENV PLUGIN_TEMPLATE=1.0.0
ENV PLUGIN_RANDOM=1.0.0
# Pip version, PIP_VERSION env is reserved by Pip
ENV PIP=9.0.3

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install with apt and pip
RUN apt-get update -y && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y \
      apt-transport-https \
      bc \
      curl \
      git \
      gosu \
      jq \
      libffi-dev \
      openssl \
      python-pip \
      libcrack2 \
      unzip && \
    `# Add google cloud` \
    echo "deb http://packages.cloud.google.com/apt cloud-sdk-xenial main" \
      | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | apt-key add - && \
    apt-get update -y && apt-get install -y \
      google-cloud-sdk="$GOOGLE_CLOUD_SDK_VERSION" && \
    `# Upgrade pip and install pip deps` \
    pip install --no-cache-dir --upgrade pip=="${PIP}" && \
    pip install --no-cache-dir \
      ansible=="$ANSIBLE_VERSION" \
      j2cli=="$J2CLI_VERSION" \
      dnspython=="$DNSPYTHON_VERSION" \
      jmespath=="$JMESPATH_VERSION" \
      apache-libcloud=="$LIBCLOUD_VERSION" \
      shade=="$SHADE_VERSION" \
      python-openstackclient=="$OPENSTACKCLIENT_VERSION" \
      python-glanceclient=="$GLANCECLIENT_VERSION" \
      awscli=="$AWSCLI_VERSION" \
      azure-cli=="$AZURE_CLI_VERSION" && \
    `# Remove unwanted` \
    rm -rf /usr/lib/gcc && \
    rm -rf /usr/share/man && \
    rm -rf /usr/lib/google-cloud-sdk/platform/gsutil && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install json2hcl
RUN curl -L "https://github.com/kvz/json2hcl/releases/download/v0.0.6/json2hcl_v0.0.6_linux_amd64" > \
    "/bin/json2hcl" && \
    chmod a+rx /bin/json2hcl

# Install Terraform
RUN curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > \
    "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
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

RUN curl "https://releases.hashicorp.com/terraform-provider-random/${PLUGIN_RANDOM}/terraform-provider-random_${PLUGIN_RANDOM}_linux_amd64.zip" > \
    "terraform-provider-random_${PLUGIN_RANDOM}_linux_amd64.zip" && \
    unzip "terraform-provider-random_${PLUGIN_RANDOM}_linux_amd64.zip" -d /terraform_plugins/ && \
    rm -f "terraform-provider-random_${PLUGIN_RANDOM}_linux_amd64.zip"

# Add KubeNow
COPY . /opt/KubeNow
