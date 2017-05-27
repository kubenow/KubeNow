#!/bin/bash

# Generate keypair
mkdir -p keypair
ssh-keygen -q -t rsa -N "" -f keypair/kubenow-ci

# Add the keypair to the agent
eval "$(ssh-agent -s)"
ssh-add keypair/kubenow-ci
