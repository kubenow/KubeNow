Kubernetes troubleshooting
==========================
Here you can find some frequently used commands to list the status and logs of kubernetes. If this doesn't help, please refer to http://kubernetes.io/docs.

.. contents::

List kubernetes pods
--------------------

::

  # If you are logged into the node via SSH:
  kubectl get pods --all-namespaces

  # With Ansible from your local computer:
  ansible master -a "kubectl get pods --all-namespaces"

Describe status of a specific pod
---------------------------------

::

  # If you are logged into the node via SSH:
  kubectl describe pod <pod id> --all-namespaces

  # With Ansible from your local computer:
  ansible master -a "kubectl describe pod <pod id> --all-namespaces"

Get the kubelet service log
---------------------------

::

  # If you are logged into the node via SSH:
  sudo journalctl -r -u kubelet

  #  With Ansible from your local computer:
  ansible master -a "journalctl -r -u kubelet"
