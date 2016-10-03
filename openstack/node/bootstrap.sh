#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# set -e

sleeptime=5
max_try_connect_time=60
cumulative_wait_time=0
echo "Try to join master..."
while :; do

  # Try to join the master
  kubeadm join --token ${kubeadm_token} ${master_ip} # 2>/dev/null
  # if join exit code was OK then exit loop
  if [ $? -eq 0 ]; then
    echo "Joinined the master..."
    exit 0
  fi
  
  if [ $cumulative_wait_time -gt $max_try_connect_time ]; then
    echo "Could not join to master in $max_try_connect_time seconds" >&2
    exit 1
  fi
  
  echo "Sleep $sleeptime before trying to join master again..."
  sleep $sleeptime
  (( cumulative_wait_time += sleeptime ))
  
done


