# Public Keys Directory

This directory can be used for dropping in the public keys of all developers/users that you wish to have access to your Kubernetes cluster. Then run the ansible playbook **upload-keys** by: `ansible-playbook playbooks/upload-keys.yml`. If you do not wish to put the public keys within the KubeNow directory you can still use the playbook by specifying your own directory by setting the variable **public_keys_dir** and run it using: `ansible-playbook playbooks/upload-keys.yml --extra-vars "public_keys_dir=/your/ssh/directory/"`.

**Note** All public key files must have the file ending **.pub**, other files in this directory will be ignored. 

