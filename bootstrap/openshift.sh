#!/bin/bash

## Add hostname
IP=$(hostname -I | cut -d ' ' -f1 | sed 's/\./-/g')
HOSTNAME=host-$IP

hostname $HOSTNAME
echo $HOSTNAME > /etc/hostname
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
