#!/bin/bash

export HOME="/home/ubuntu"
sudo apt update && apt upgrade -y
apt install -y python3 pipx git
pipx install ansible 
########################################################################
# keypair for communication with other instances
########################################################################

sudo -u ubuntu mkdir -p $HOME/.ssh
echo "${private_key}" | sudo tee $HOME/.ssh/deployment_key > /dev/null
echo "${public_key}" | sudo tee $HOME/.ssh/deployment_key.pub > /dev/null
sudo chmod 600 $HOME/.ssh/deployment_key
sudo chmod 644 $HOME/.ssh/deployment_key.pub
sudo chown ubuntu:ubuntu $HOME/.ssh/deployment_key $HOME/.ssh/deployment_key.pub

########################################################################
# create ansible inventory file
########################################################################
# ensure /etc/ansible directory exists
if [ ! -d "/etc/ansible" ]; then
    sudo mkdir -p /etc/ansible
    sudo chmod 755 /etc/ansible
fi
cat <<EOF | sudo tee /etc/ansible/hosts
[backend]
%{ for ip in backend_private_ip_list }
${ip} ansible_user=ubuntu
%{ endfor }

[frontend]
%{ for ip in frontend_private_ip_list }
${ip} ansible_user=ubuntu
%{ endfor }

[all:vars]
ansible_ssh_private_key_file=~/.ssh/deployment_key
EOF
