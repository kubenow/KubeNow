Image build instructions
========================

KubeNow uses prebuilt images to speed up the deployment. Even if we provide some prebuilt images you may need to build it yourself. The procedure is slightly different for each host cloud. Here you find a section for each of the supported providers.

.. contents:: Sections
  :depth: 2

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
