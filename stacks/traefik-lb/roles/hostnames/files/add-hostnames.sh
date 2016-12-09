#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# extract from kubectl output
hoststring=`kubectl get nodes -o jsonpath='{.items[*].metadata.name}'`
ipstring=`kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'`

# into arrays
ipnumbers=($ipstring)
hostnames=($hoststring)

for ((i=0;i<${#ipnumbers[@]};++i)); do
    echo "${ipnumbers[i]} ${hostnames[i]}" >> /etc/hosts
done
