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


openssl: error while loading shared libraries: libssl.so.1.0.0: cannot open shared object file: No such file or directory
and:
==> vagrant-master-01: failed to generate token(s) [[tokens] Provided token does not match expected <6 characters>.<16 characters> format - length of first part is incorrect [0 (given) != 6 (expected) ]]

It was fixed by this symlink:
sudo ln -sf /usr/local/bin/openssl /opt/vagrant/embedded/bin/openssl
