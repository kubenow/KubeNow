More troubleshooting
====================

.. contents::

SSH connection errors
---------------------
In case of SSH connection errors:

- Make sure to add your private SSH key to your local keyring:

::

  ssh-add ~/.ssh/id_rsa

- Make sure that port 22 is allowed in your cloud provider security settings.

If you still experience problems, checking out the console logs from your cloud provider could help.

Figure out hostnames and IP numbers
-----------------------------------
The bootstrap step should create an Ansible inventory list, which contains hostnames and IP addresses::

  cat inventory
