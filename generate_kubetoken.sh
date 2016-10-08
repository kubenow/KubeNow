#!/bin/bash
# kube token format: 7fa96f.ddb39492a1894689
# see https://github.com/kubernetes/kubernetes/blob/master/cmd/kubeadm/app/util/tokens.go
tokenID=`openssl rand -hex 3`
tokenVal=`openssl rand -hex 8`
token="$tokenID.$tokenVal"
echo $token
