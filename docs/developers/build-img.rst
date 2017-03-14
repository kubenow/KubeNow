Image build instructions
========================

KubeNow uses prebuilt images to speed up the deployment. Even if we provide some prebuilt images you may need to build it yourself. The procedure is slightly different for each host cloud. Here you find a section for each of the supported providers.

.. contents:: Sections
  :depth: 2

Build KubeNow image on OpenStack
--------------------------------

Prerequisites
~~~~~~~~~~~~~

In this section we assume that:

- You have downloaded and sourced the OpenStack RC file for your tenancy: ``source project-openrc.sh``

Every OpenStack installation it's a bit different, and the RC file you get to download from the interface might be incomplete. Please make sure that all of these environment variables are set in the RC file::

  OS_USERNAME
  OS_PASSWORD
  OS_AUTH_URL
  OS_USER_DOMAIN_ID
  OS_DOMAIN_ID
  OS_REGION_NAME
  OS_PROJECT_ID
  OS_TENANT_ID
  OS_TENANT_NAME
  OS_AUTH_VERSION

- You created a private network with a router that connects it to the external network
- You have a Ubuntu 16.04 (Xenial) image in your tenancy
- You set up the default security group to allow ingress traffic on port 22

Build the KubeNow image
~~~~~~~~~~~~~~~~~~~~~~~

Start by creating a ``packer-conf.json`` file. There is a template that you can use for your convenience: ``mv packer-conf.json.os-template packer-conf.json``. In this configuration file you will need to set:

- **image_name**: the name of the image that will be created after the build (e.g. "KubeNow")
- **source_image_name**: a Ubuntu Xenial image, already present in your tenancy
- **network**: the ID of a private network, already present in your tenancy
- **flavor**: an instance flavor to use, in order to build the image
- **floating_ip_pool**: a floating IP pool

Once you are done with your settings you are ready to build KubeNow using Packer::

  packer build -var-file=packer-conf.json packer/build-openstack.json

If everything goes well, you will see the new image in the OpenStack web interface (Compute > Images). As an alternative, you can check that the image is present using the OpenStack command line client::

  glance image-list

Build KubeNow image on GCE
--------------------------

Prerequisites
~~~~~~~~~~~~~

In this section we assume that:

- You have enabled the Google Compute Engine API: API Manager > Library > Compute Engine API > Enable
- You have created and downloaded a service account file for your GCE project: Api manager > Credentials > Create credentials > Service account key

Build the KubeNow image
~~~~~~~~~~~~~~~~~~~~~~~

Start by creating a ``packer-conf.json`` file. There is a template that you can use for your convenience: ``mv packer-conf.json.gce-template packer-conf.json``. In this configuration file you will need to set:

- **image_name**: the name of the image that will be created after the build (the name must match ``(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)``, e.g. "kubenow-image")
- **source_image_name**: a Ubuntu Xenial image (this should already be in GCE, e.g. ``ubuntu-1604-xenial-v20161013``)
- **account_file**: path to your service account file
- **zone**: the zone to use in order to build the image (e.g. ``europe-west1-b``)
- **project_id**: your project id

Once you are done with your settings you are ready to build KubeNow using Packer::

  packer build -var-file=packer-conf.json packer/build-gce.json

If everything goes well, you will see the new image in the GCE web interface (Compute Engine > Images). As an alternative, you can check that the image is present using the Google Cloud command line client::

  gcloud compute images list

Build KubeNow image on Amazon Web Services (EC2)
------------------------------------------------

Prerequisites
~~~~~~~~~~~~~

In this section we assume that:

- You have an IAM user along with its *access key* and *security credentials* (http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)

Build the KubeNow image
~~~~~~~~~~~~~~~~~~~~~~~

The first time you are going to deploy KubeNow, you'll have to create its cloud image. This considerably speeds up the following bootstraps, as all of the required software will already be installed on the instances.

Start by creating a ``packer-conf.json`` file. There is a template that you can use for your convenience: ``mv packer-conf.json.aws-template packer-conf.json``. In this configuration file you will need to set:

- **image_name**: the name of the image that will be created after the build (e.g. "kubenow-image")

  + **Warning:** the image_name must be unique in AWS, otherwise it will fail creating the new image

- **source_image_id**: an Ubuntu Xenial AMI ID

  + **Tip:** to figure out an Ubuntu Xenial AMI ID that works with your preferred region, you can use the `Amazon EC2 AMI Locator <https://cloud-images.ubuntu.com/locator/ec2/>`_
  + **Warning:** we support only `hvm:ebs-ssd` AMIs (other AMIs might work anyway)

- **aws_access_key_id**: your access key id
- **aws_secret_access_key**: your secret access key
- **region**: the region to use in order to create the image

  + **Warning:** the image that you previously selected has to be available in this region

Once you are done with your settings you are ready to build KubeNow using Packer::

  packer build -var-file=packer-conf.json packer/build-aws.json

If everything goes well, something like the following will be printed out::

  ==> Builds finished. The artifacts of successful builds are:
  --> amazon-ebs: AMIs were created:

  eu-central-1: ami-XXXX

**Tip:** write down region and AMI ID for this KubeNow image build, as it will be useful in the next step.

In addition, you will see the new image in the Amazon web interface (EC2 Dashboard > Images > AMIs). You might need to change your location in the dashboard for your image to be shown.

As an alternative, you can check that the image is present using the amazon cloud command line client::

  aws ec2 describe-images --owners self
