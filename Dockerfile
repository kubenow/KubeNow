FROM python:2.7-alpine
MAINTAINER "Marco Capuccini <marco.capuccini@it.uu.se>"

# Provisioners versions
ENV TERRAFORM_VERSION=0.9.4
ENV TERRAFORM_SHA256SUM=0cbb5474c76d878fbc99e7705ce6117f4ea0838175c13b2663286a207e38d783
ENV ANSIBLE_VERSION=2.2.0.0
ENV LIBCLOUD_VERSION=1.5.0

# Install APK deps
RUN apk add --update \
  git \
  curl \
  openssh \
  build-base \
  linux-headers \
  libffi-dev \
  openssl-dev \
  openssl

# Install PIP deps
RUN pip install \
  ansible==$ANSIBLE_VERSION \
  j2cli \
  dnspython \
  jmespath \
  apache-libcloud==$LIBCLOUD_VERSION \
  shade

# Install Terraform
RUN curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > \
    terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    echo "${TERRAFORM_SHA256SUM}  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > \
    terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin && \
    rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Add KubeNow (and group)
COPY . /opt/KubeNow
WORKDIR /opt/KubeNow

# Set entrypoint
ENTRYPOINT ["sh","-c"]
