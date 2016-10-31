#!/bin/bash

SLEEPTIME=5 # Sec
MAX_TRY_CONNECT_TIME=600 # Sec

cumulative_wait_time=0
echo "Try to join master..."
while [ $cumulative_wait_time -lt $MAX_TRY_CONNECT_TIME ] ; do

  # Try to join the master
  kubeadm join --token ${kubeadm_token} ${master_ip}
  # If join exit code was OK then exit loop
  if [ $? -eq 0 ]; then
    echo "Joinined the master..."
    exit 0
  fi

  echo "Sleep $SLEEPTIME before trying to join master again..."
  sleep $SLEEPTIME
  (( cumulative_wait_time += SLEEPTIME ))

done

echo "Could not join to master in $MAX_TRY_CONNECT_TIME seconds" >&2
exit 1
