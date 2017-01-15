 #!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

vagrant up
vagrant halt
vagrant package --output /tmp/kubenow.box
vagrant box add --clean --name kubenow /tmp/kubenow.box
rm /tmp/kubenow.box


