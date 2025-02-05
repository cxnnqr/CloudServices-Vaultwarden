#!/bin/bash

# Update package lists and install necessary packages
apt-get update
apt-get -y install apache2 python3

# Configure Apache index page
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

########################################################################
# Install Prometheus Node Exporter
########################################################################

# Create a dedicated user for Node Exporter (for security reasons)
sudo useradd --no-create-home --shell /bin/false node_exporter

# Download and extract Node Exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xvf node_exporter-1.8.2.linux-amd64.tar.gz
mv node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/

# Set correct permissions
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create required directories and set permissions
sudo mkdir -p /var/lib/node_exporter
sudo chown -R node_exporter:node_exporter /var/lib/node_exporter
sudo chmod -R 775 /var/lib/node_exporter

########################################################################
# Create systemd service for Node Exporter
########################################################################

cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable, and start Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "Node Exporter setup completed successfully!"
