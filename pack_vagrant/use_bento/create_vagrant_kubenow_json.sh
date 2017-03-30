#!/bin/bash
set -e

# export ATLAS_ORG=my org
# export ATLAS_TOKEN= token is stored somewhere else:)

BOX_VERSION="0.0.3"
BOX_BASENAME="kubenow"
DISK_SIZE=614400


# Install bento (for uploading)
#gem install bento-ya

# clone bento 
#git clone https://github.com/chef/bento.git
cd bento
#git checkout 2.3.2

# create kubenow packer json by replacing vars in default
# ubuntu.json

# generate random password
# PASSWORD=$(openssl rand -base64 32)
PASSWORD="vagrant"


FIND='"scripts/ubuntu/cleanup.sh",'
INSERT='"\.\./\.\./\.\./packer/requirements\.sh",'
REPLACE="$INSERT\n$FIND"

sed "s#$FIND#$REPLACE#" ubuntu-16.04-amd64.json > kubenow.json
  
# build it
#bento build --only=virtualbox-iso kubenow
packer build --only=virtualbox-iso \
             --force \
             -var "box_basename=$BOX_BASENAME" \
             -var "name=$BOX_BASENAME" \
             -var "template=$BOX_BASENAME" \
             -var "version=$BOX_VERSION" \
             -var "disk_size=$DISK_SIZE" \
             kubenow.json

# create meta.json
META=$(cat <<EOF
{
  "name": "$BOX_BASENAME",
  "version": "$BOX_VERSION",
  "box_basename": "$BOX_BASENAME",
  "template": "$BOX_BASENAME",
  "cpus": "1",
  "memory": "1024",
  "providers": [
    {
      "name": "virtualbox",
      "file": "$BOX_BASENAME-$BOX_VERSION.virtualbox.box"
    }
  ]
}
EOF
)
echo $META > "builds/$BOX_BASENAME-$BOX_VERSION.virtualbox.json"

# upload it
# bento upload

# release it
# bento release $BOX_BASENAME $BOX_VERSION
