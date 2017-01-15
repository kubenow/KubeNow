#!/bin/bash

export ATLAS_TOKEN=tQDwsBXIxVVh5A.atlasv1.W757BfoYRjN00wykW6rf3CQ8RJ1IobTqCg7VVtznEkSYMe9u44ivtTJx3mWftbSYlq0
export ATLAS_ORG=kubenow

BOX_VERSION="0.0.2"
BOX_BASENAME="kubenow"
#BOX_BASENAME="kubenow-cloudportal"

# Install bento (for uploading)
#gem install bento-ya

# clone bento 
#git clone https://github.com/chef/bento.git
cd bento
git checkout 2.3.2

# create kubenow packer json by replacing vars in default
# ubuntu.json

FIND='"scripts/ubuntu/cleanup.sh",'
INSERT='"\.\./\.\./\.\./packer/requirements\.sh",'
REPLACE="$INSERT\n$FIND"

sed "s#$FIND#$REPLACE#" ubuntu-16.04-amd64.json |
  jq ".variables.box_basename = \"$BOX_BASENAME-$BOX_VERSION\"" |
  jq ".variables.name = \"$BOX_BASENAME\"" |
  jq ".variables.template = \"$BOX_BASENAME\"" |
  jq ".variables.version = \"$BOX_VERSION\"" > kubenow.json
  

# build it
#bento build --only=virtualbox-iso kubenow
packer build -only=virtualbox-iso kubenow.json

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
bento upload

# release it
bento release $BOX_BASENAME $BOX_VERSION
