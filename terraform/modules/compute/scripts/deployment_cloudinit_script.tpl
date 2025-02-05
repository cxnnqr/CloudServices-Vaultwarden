#!/bin/bash

export HOME="/home/ubuntu"

# Update and install required packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 pipx git

# Install Ansible using pipx
pipx install ansible 

########################################################################
# Keypair for communication with other instances
########################################################################

sudo -u ubuntu mkdir -p $HOME/.ssh
echo "${private_key}" | sudo tee $HOME/.ssh/deployment_key > /dev/null
echo "${public_key}" | sudo tee $HOME/.ssh/deployment_key.pub > /dev/null
sudo chmod 600 $HOME/.ssh/deployment_key
sudo chmod 644 $HOME/.ssh/deployment_key.pub
sudo chown ubuntu:ubuntu $HOME/.ssh/deployment_key $HOME/.ssh/deployment_key.pub

########################################################################
# Create Ansible inventory file
########################################################################

# Ensure /etc/ansible directory exists
if [ ! -d "/etc/ansible" ]; then
    sudo mkdir -p /etc/ansible
    sudo chmod 755 /etc/ansible
fi

# Define the inventory file
cat <<EOF | sudo tee /etc/ansible/hosts
[vault]
%{ for ip in backend_private_ip_list }
${ip} ansible_user=ubuntu
%{ endfor }

[ingress]
%{ for ip in frontend_private_ip_list }
${ip} ansible_user=ubuntu
%{ endfor }

[all:vars]
ansible_ssh_private_key_file=~/.ssh/deployment_key
EOF

########################################################################
# Install Prometheus Server
########################################################################

# Create a dedicated user for Prometheus (security best practice)
sudo useradd --no-create-home --shell /bin/false prometheus

# Download and extract Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.53.3/prometheus-2.53.3.linux-amd64.tar.gz
tar xvf prometheus-2.53.3.linux-amd64.tar.gz
mv prometheus-2.53.3.linux-amd64 /opt/prometheus

# Set correct ownership and permissions
sudo chown -R prometheus:prometheus /opt/prometheus

# Create Prometheus directories and fix permissions
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
sudo chmod -R 775 /var/lib/prometheus

# Ensure the required query log file exists
sudo touch /var/lib/prometheus/queries.active
sudo chown prometheus:prometheus /var/lib/prometheus/queries.active
sudo chmod 664 /var/lib/prometheus/queries.active

# Move the Prometheus binary files to standard locations
ln -s /opt/prometheus/prometheus /usr/local/bin/prometheus
ln -s /opt/prometheus/promtool /usr/local/bin/promtool

########################################################################
# Create Prometheus Configuration File
########################################################################

cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'backend'
    static_configs:
      - targets:
%{ for ip in backend_private_ip_list }
        - '${ip}:9100'
%{ endfor }

  - job_name: 'frontend'
    static_configs:
      - targets:
%{ for ip in frontend_private_ip_list }
        - '${ip}:9100'
%{ endfor }
EOF

# Set correct ownership
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

########################################################################
# Create Prometheus systemd service
########################################################################

cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus Server
After=network.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus \
    --web.listen-address=0.0.0.0:9090
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start Prometheus service
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

########################################################################
# Install and Configure Grafana
########################################################################

# Install Grafana
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update && sudo apt install -y grafana

# Enable and start Grafana service
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Wait for Grafana to start
sleep 10

# Configure Prometheus as the default data source
sudo mkdir -p /etc/grafana/provisioning/datasources

cat <<EOF | sudo tee /etc/grafana/provisioning/datasources/prometheus.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
EOF

# Restart Grafana to apply changes
sudo systemctl restart grafana-server

########################################################################
# Import Custom Dashboard from JSON
########################################################################

cat <<EOF > /tmp/custom-dashboard.json
{
  "dashboard": {
    "annotations": {
      "list": [
        {
          "builtIn": 1,
          "datasource": {
            "type": "grafana",
            "uid": "-- Grafana --"
          },
          "enable": true,
          "hide": true,
          "iconColor": "rgba(0, 211, 255, 1)",
          "name": "Annotations & Alerts",
          "type": "dashboard"
        }
      ]
    },
    "editable": true,
    "fiscalYearStartMonth": 0,
    "graphTooltip": 0,
    "id": null,
    "links": [],
    "panels": [
      {
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "mappings": [
              {
                "options": {
                  "0": {
                    "color": "red",
                    "index": 1,
                    "text": "DOWN"
                  },
                  "1": {
                    "color": "green",
                    "index": 0,
                    "text": "UP"
                  }
                },
                "type": "value"
              }
            ],
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {
                  "color": "green",
                  "value": null
                },
                {
                  "color": "red",
                  "value": 80
                }
              ]
            }
          },
          "overrides": []
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        },
        "id": 1,
        "options": {
          "colorMode": "background",
          "graphMode": "area",
          "justifyMode": "auto",
          "legend": {
            "calcs": [],
            "displayMode": "list",
            "placement": "bottom",
            "showLegend": true
          },
          "orientation": "auto",
          "percentChangeColorMode": "standard",
          "reduceOptions": {
            "calcs": [],
            "fields": "",
            "values": false
          },
          "showPercentChange": false,
          "textMode": "auto",
          "wideLayout": true
        },
        "pluginVersion": "11.5.1",
        "targets": [
          {
            "datasource": {
              "type": "prometheus",
              "uid": "PBFA97CFB590B2093"
            },
            "editorMode": "builder",
            "expr": "up",
            "legendFormat": "{{job}}: {{ instance }}",
            "range": true,
            "refId": "A"
          }
        ],
        "title": "Example Panel",
        "type": "stat"
      }
    ],
    "preload": false,
    "refresh": "5s",
    "schemaVersion": 40,
    "tags": [
      "custom"
    ],
    "templating": {
      "list": []
    },
    "time": {
      "from": "now-6h",
      "to": "now"
    },
    "timepicker": {},
    "timezone": "browser",
    "title": "My Custom Dashboard",
    "uid": "custom_dashboard",
    "version": 2,
    "weekStart": ""
  },
  "overwrite": true,
  "folderId": 0,
  "inputs": [
    {
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "Prometheus"
    }
  ]
}
EOF

# Use the Grafana API to import the custom dashboard
until curl -s http://localhost:3000/api/health | grep -q "ok"; do
    echo "Grafana is not ready yet. Waiting..."
    sleep 5
done
curl -X POST -H "Content-Type: application/json" -d @/tmp/custom-dashboard.json \
  http://admin:admin@localhost:3000/api/dashboards/import


# install node exporter dashboard
sudo apt install -y jq
curl -s https://grafana.com/api/dashboards/1860/revisions/latest/download -o /tmp/dashboard-1860.json
jq '{ "dashboard": ., "overwrite": true, "folderId": 0, "inputs": [{ "name": "DS_PROMETHEUS", "type": "datasource", "pluginId": "prometheus", "value": "Prometheus" }] }' /tmp/dashboard-1860.json > /tmp/dashboard-1860-modified.json
curl -X POST -H "Content-Type: application/json" -d @/tmp/dashboard-1860-modified.json http://admin:admin@localhost:3000/api/dashboards/import


echo "Prometheus and Grafana installation completed successfully!"