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

[databases]

[all:vars]
ansible_ssh_private_key_file=~/.ssh/deployment_key
EOF

# ########################################################################
# # build vaultwarden backend
# ########################################################################
# export HOME="/root"
# sudo apt update && apt upgrade -y
# if ! command -v rustup &> /dev/null; then
#     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# fi

# if ! command -v cargo &> /dev/null; then
# source "$HOME/.cargo/env"
# fi

# sudo apt install -y curl build-essential git pkg-config libssl-dev libmariadb-dev-compat libmariadb-dev nodejs

# if ! command -v vaultwarden &> /dev/null; then
#     # clone repo and build bin
#     cd /tmp || exit 1
#     git clone https://github.com/dani-garcia/vaultwarden
#     cd vaultwarden || exit 1
#     cargo build --features mysql --release
#     sudo mv target/release/vaultwarden /usr/local/bin/vaultwarden
# fi
# if ! command -v vaultwarden &> /dev/null; then
#         echo "Failed to install Vaultwarden."
#         exit 1
#     fi
# echo "Vaultwarden backend build completed successfully."

# ########################################################################
# # install docker
# ########################################################################
# sudo apt update && apt upgrade -y
# # see: https://docs.docker.com/engine/install/ubuntu/
# # Add Docker's official GPG key:
# sudo apt-get install -y ca-certificates curl 
# sudo install -m 0755 -d /etc/apt/keyrings
# sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
# sudo chmod a+r /etc/apt/keyrings/docker.asc


# # Add the repository to Apt sources:
# echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
#   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt-get update
# # install docker
# sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# # post install
# #groupadd docker # already installed by package normally
# usermod -aG docker ubuntu # add default cloud image user to docker group
# # autostart docker on reboot
# systemctl enable docker.service
# systemctl enable containerd.service
# # check if installation was successful
# if command -v docker &> /dev/null; then
#     echo "Docker was successfully installed and is available."
#     # Optionally check the Docker version
#     docker --version
# else
#     echo "Docker installation failed. Please check the logs and try again."
#     exit 1
# fi

