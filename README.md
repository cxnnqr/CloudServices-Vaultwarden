# Vaultwarden Infrastructure on OpenStack

This project contains Terraform configurations to deploy a highly available Vaultwarden infrastructure on OpenStack. The infrastructure includes frontend servers, backend servers, load balancers, and a deployment instance with monitoring capabilities.

## Architecture

The infrastructure consists of:
- Multiple frontend instances behind a load balancer
- Two backend instances, one is for failover
- A deployment instance with Prometheus and Grafana for monitoring
- Network configuration with security groups
- Automated instance configuration using cloud-init scripts

## Prerequisites

- Terraform >= 0.14.0
- OpenStack credentials configured
- SSH key pair for instance access
- OpenStack CA certificate

## Quick Start

1. Clone this repository
    ```bash
    git clone https://github.com/cxnnqr/vaultwarden.git
    cd vaultwarden
    ```

2. Copy and configure the variables file:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your specific values:
   ```hcl
   public_key              = "~/.ssh/your_key.pub"
   group_name             = "your-group-name"
   router_name            = "your-router-name"
   global_image_name      = "ubuntu-22.04-jammy-server-cloud-image-amd64" #default
   backend_instance_count  = 2 #default
   frontend_instance_count = 3 #default
   pubnet_name            = "ext_net" #default
   dns_nameservers        = ["8.8.8.8"] #default
   ```

4. Initialize Terraform:
   ```bash
   cd terraform
   terraform init
   ```

5. Deploy the infrastructure:
   ```bash
   terraform plan -out tf.plan
   terraform apply "tf.plan"
   ```

## Monitoring

The deployment instance includes:
- Prometheus for metrics collection
- Node Exporter on all instances
- Grafana for visualization
- Pre-configured dashboards

Access Grafana at: `http://<deployment_floating_ip>:3000`
- Default credentials: admin/admin

## Outputs

After deployment, Terraform will output:
- Frontend load balancer IP
- Deployment instance IP

## Security Groups

The configuration includes security groups with rules for:
- HTTP (80)
- SSH (22)
- Prometheus (9090)
- Node Exporter (9100)
- Grafana (3000)

## Module Structure

- `compute/`: Instance configurations
- `keypairs/`: SSH key management
- `loadbalancer/`: Load balancer configurations
- `network/`: Network and subnet setup
- `security/`: Security group definitions

## Technology used

This project uses several open-source components that are licensed under different terms:

### Infrastructure Components

- **Terraform** - Mozilla Public License 2.0 (MPL-2.0)
- **OpenStack Provider for Terraform** - Mozilla Public License 2.0 (MPL-2.0)

### Monitoring Stack

- **Prometheus** - Apache License 2.0
- **Node Exporter** - Apache License 2.0
- **Grafana** - GNU Affero General Public License v3.0 (AGPL-3.0)

### Development Tools

- **Ansible** - GNU General Public License v3.0 (GPL-3.0)
- **Docker** (via Ansible collection) - Apache License 2.0

#### ansible-galaxy collection

- **community.docker**: `ansible-galaxy collection install community.docker`
- **community.mysql**: `ansible-galaxy collection install community.mysql`

### Operating System and Packages

- **Ubuntu** - Various open-source licenses (primarily GPL and LGPL)
- **Python3** - Python Software Foundation License (PSF)

### Note on License Compliance

When using this project, ensure you comply with all the licenses of the components used. Key points:

1. The Grafana AGPL-3.0 license requires that if you modify and distribute Grafana, you must make your modifications available under the same license.

2. The MPL-2.0 license (Terraform) requires that any modifications to the covered files must be released under MPL-2.0.

3. For detailed license information and compliance requirements, please refer to the respective project websites:
   - Terraform: https://github.com/hashicorp/terraform/blob/main/LICENSE
   - Prometheus: https://github.com/prometheus/prometheus/blob/main/LICENSE
   - Grafana: https://github.com/grafana/grafana/blob/main/LICENSE
   - Ansible: https://github.com/ansible/ansible/blob/devel/COPYING
