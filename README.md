# Deploying a cluster that runs any combination of Vault, Consul, Nomad or Terraform (HashiStack)

This repository is a one-size-fits-all approach to get easily started with the deployment of any of the above mentioned HashiCorp tools on AWS. The main focus is about simplicity and readability. It is purely based on Terraform IaC. The cluster TLS certs are provided by hashicorp/terraform-provider-tls. The instances are configured via "user-data" scripts (bash). The "user-data" scripts are dynamically rendered (hashicorp/terraform-provider-template) based on the assigned values in variables.tf.

---
> Its behavor can be customized by changing/overriding the defaults in variables.tf. (**take a look at the examples at the bottom**).
>
> Take a look at the **outputs** to find the IP addresses of the instances or the initial password to get access to the Terraform Enterpise admin page on port 8800.
>
> Use `apt-cache show vault-enterprise` to identiy a proper version string of a Enterprise version.
---

***Cluster Features***

- variable cluster size (typical 1,3, or 5)
- auto_join of server nodes
- raft-clustering
- raft storage backend
- configurable ingress CIDR (ACL)

***Vault Features***

- auto-unseal (AWS_KMS)
- TLS encryption

***Consul Features***

- TLS encryption
- Gossip encryption
- ACL bootstrapping

***Nomad Features***

- configurable amount of worker nodes
- auto bootstrapping

***Terraform Enterprise Features***

- letsenrypt (certbot) TLS
- airgapped license support
- "mounted disk" storage backend

---

## Content of the repository

| File | Description |
| - | :- |
| README.md | This README |
| templates/base.sh | user_data template for generic settings on the instance(s) |
| templates/server.sh | user_data template to setup the service(s) on instance(s) |
| templates/client.sh | user_data template to setup the Nomad worker node(s) |
| templates/docker.sh | user_data template to setup Docker extension on Nomad worker node(s) |
| templates/tfe.sh | user_data template to setup Terraform Enterprise on the instance |
| main.tf | Provider related configurations and network configurations |
| server.tf | Cluster instances include rendering of user_data templates |
| clients.tf | Nomad worker instances include rendering of user_data templates |
| tfe.tf | Terraform Enterprise instance include rendering of user_data templates |
| iam.tf | AWS IAM roles and policy authorization for the instances (autojoin) |
| kms.tf | Key Management Service that stores Vault unseal keys (auto unseal) |
| tls.tf | TLS certificates for the services based on terraform_tls_provider |
| variables.tf | Variables to customize the hashistack |
| outputs.tf | Outputs and post build-time information |

---

## Variable Argument Reference

| Key | Description | Default |
| - | :- | :- |
| **Global Settings**
| aws_region | (required) The AWS region to be used | none |
| name | (required) Environment name to be used as Tag  | none |
| server_count | (optional) Amount of cluster instances (odd number 1,3, max 5) | 3 |
| instance_type | (optional) Type of EC2 cluster instance | t2.small |
| server_name | (optional) Hostname prefix of the cluster instances | hc-stack-srv |
| root_block_device_size | (optional) Size of the root filesystem | 80 |
| auto_join_value | (optional) Server rejoin tag_value to identify cluster instances | joestack_hashistack_autojoin |
| dns_domain | (required) The Route53 Zone to assign DNS records to | none |
| key_name | (optional) SSH key_name to be used to access the instances | aws-hashistack-key |
| aws_hashistack_key | (required if key_name default is not changed) The SSH public key to access any instance | NULL |
| whitelist_ip | (optional) The allowed ingress IP CIDR assigned to the ASGs | 0.0.0.0/0 |
| network_address_space | (optional) The CIDR to be used for the instances | 172.16.0.0/16 |
| create_root_ca | (optional) Create a self-signed root ca based on hashicorp/terraform-provider-tls | true |
| common_name | (optional) Common Name of the CA | hashistack |
| organization | (optional) Organization of the CA | joestack |
| **Vault Settings**
| vault_enabled | (optional) Create a Vault cluster [true, false] | false |
| vault_version | (required if vault_enabled) The Vault version to be used [1.9.3, 1.9.3+ent] | 1.9.3 |
| vault_lic | (required if +ent) The Vault license in case of using Vault Enterprise | NULL |
| vault_tls_enabled | (optional) Using Vault with TLS enabled [true, false] | true |
| **Consul Settings**
| consul_enabled | (optional) Create a Consul cluster [true, false] | false |
| consul_version | (required if consul_enabled) The Consul version to be used [1.13.3, 1.13.3+ent-1] | 1.13.3 |
| consul_lic | (required if +ent) The Consul license in case of using Consul Enterprise | NULL |
| consul_tls_enabled | (optional) Using Consul with TLS enabled [true, false] | true |
| **Nomad Settings**
| nomad_enabled | (optional) Create a Nomad cluster [true, false] | false |
| nomad_version | (required if nomad_enabled) The Nomad version to be used [1.2.5, 1.2.5+ent] | 1.2.5 |
| nomad_lic | (required if +ent) The Nomad license in case of using Nomad Enterprise | NULL |
| nomad_bootstrap | (optional) Automatically bootrstrap the Nomad cluster [true, false] | false |
| datacenter | (optional) The name of the Datacenter | dc1 |
| region | (optional) The name of the region | global |
| client | (optional) Install Nomad clients/worker as well [true, false] | true |
| client_count | (optional) The amount of Nomad clients | 3 |
| client_name | (optional) Hostname prefix of Nomad clients | nmd-worker |
| **Terraform Settings**
| terraform_enabled | (optional) Create a Terraform Enterprise instance [true, false] | false |
| tfe_lic | (required if terraform_enabled) The Terraform Enterprise license (must be base64 encoded in case of airgapped). | NULL |
| tfe_airgapped | (optional) In case of using an airgap enabled license [true, false] | false |
| tfe_auth_password | (optional) The initial authentication password. Will be created if NULL | NULL |
| tfe_enc_password | (optional) The encryption key to be used to encrypt state and db. Will be created if NULL | NULL |
| tfe_hostname | (optional) The hostname of the TFE instance | tfe-joestack |
| tfe_cert_provider | (optional) TLS Certificate options [self-signed, certbot, tf-tls-provider] | certbot |
| tfe_cert_email | (required if certbot) Certbot email address | none |
| tfe_auto_install | (optional) Automatically install TFE on instance [true, false] | true |

---

## Examples

### Terraform Enterprise only with Letsencrypt certificate

    aws_region = "eu-west-1"
    name = "my_hashistack"
    dns_domain = "hashidemos.io"
    aws_hashistack_key "ssh-rsa AA....."
    terraform_enabled = "true"
    tfe_lic = "ey......"
    tfe_cert_email = "foo@example.io"

#### 3 Node Vault and Consul Cluster

    aws_region = "eu-west-1"
    name = "my_hashistack"
    dns_domain = "hashidemos.io"
    aws_hashistack_key "ssh-rsa AA....."
    vault_enabled = "true"
    vault_version = "1.9.3"
    consul_enabled = "true"
    consul_version = "1.13.3"

#### 3 Node Vault Enterprise Cluster

    aws_region = "eu-west-1"
    name = "my_hashistack"
    dns_domain = "hashidemos.io"
    aws_hashistack_key "ssh-rsa AA....."
    vault_enabled = "true"
    vault_version = "1.9.3+ent"
    vault_lic = "02MV....."

#### 5 Node Vault Ent, Consul Ent, Nomad Ent Cluster with 7 Worker Nodes and Terraform Enterprise

    aws_region = "eu-west-1"
    name = "my_hashistack"
    server_count = "5"
    dns_domain = "hashidemos.io"
    aws_hashistack_key "ssh-rsa AA....."
    vault_enabled = "true"
    vault_version = "1.12.2+ent-1"
    vault_lic = "02MV....."
    consul_enabled = "true"
    consul_version = "1.14.3+ent-1"
    consul_lic = "02MV....."
    nomad_enabled = "true"
    nomad_version = "1.2.5+ent"
    nomad_lic = "01MV....."
    client_count = "7"
    terraform_enabled = "true"
    tfe_lic = "ey......"
