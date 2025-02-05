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
