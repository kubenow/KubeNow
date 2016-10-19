Terraform troubleshooting
=========================
Since Terraform applies changes incrementally, when there is a minor issue (e.g. network timeout) it's sufficient to rerun the command. However, here we try to collect some tips that can be useful when rerunning the command doesn't help.

.. contents::

Corrupted Terraform state
-------------------------
Due to network issues, Terraform state files can get out of synch with your infrastructure, and cause problems. Since Terraform apply changes increme. A possible way to fix the issue is to destroy your nodes manually, and remove all state files and cached modules::

  rm -R .terraform/
  rm terraform.tfstate
  rm terraform.tfstate.backup
