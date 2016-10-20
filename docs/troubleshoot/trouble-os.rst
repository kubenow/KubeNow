OpenStack troubleshooting
=========================

.. contents::

Console logs on OpenStack
-------------------------

Can't get the status from the nodes with ``ansible master -a "kubectl get nodes"``? The nodes might not have started all right. Checking the console logs with nova could help.

List node IDs, floating IPs etc.::

  nova list

Show console output from node of interest::

  nova console-log <node-id>
