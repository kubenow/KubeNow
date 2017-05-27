#!/bin/bash

# Destroy no matter what!
travis_retry terraform destroy -force "$HOST_CLOUD"
