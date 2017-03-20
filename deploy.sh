sed -i -e 's/domain_name/uservice.se/g' examples/cheese-deployment.yml
ansible master -m copy -a "src=examples/cheese-deployment.yml dest=/home/ubuntu"
ansible master -a "kubectl apply -f /home/ubuntu/cheese-deployment.yml"
