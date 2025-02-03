#!/bin/bash
apt-get update
apt-get -y install apache2 python3
rm /var/www/html/index.html
cat > /var/www/html/index.html << INNEREOF
<!DOCTYPE html>
<html>
  <body>
    <h1>It works!</h1>
    <p>terraform-instance-${instance_number}</p>
  </body>
</html>
INNEREOF
sed -i "s/hostname/terraform-instance-${instance_number}/" /var/www/html/index.html
sed -i "1s/$/ terraform-instance-${instance_number}/" /etc/hosts

# Add public key of deployment instance to authorized_keys
export HOME="/home/ubuntu"
sudo -u ubuntu mkdir -p $HOME/.ssh
echo "${public_key}" | sudo -u ubuntu tee -a $HOME/.ssh/authorized_keys > /dev/null
sudo chmod 600 $HOME/.ssh/authorized_keys
sudo chown ubuntu:ubuntu $HOME/.ssh/authorized_keys