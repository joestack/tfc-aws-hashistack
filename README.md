# tfc-aws-hashistack

This is a one-size-fits-all approach to setup Terraform Enterprise, Vault, Consul, Nomad or any combination of them.

Its behavor can be customized by changing/overriding the defaults in variables.tf

Vault: TLS encryption, auto-unseal, auto-join, raft-storage -> you can start with "vault operator init"

Consul: TLS encryption, gossip encryption, ACL bootstrapping 

Nomad: Auto bootstrapping, variable amount of workers (can be configured in variables.tf as well)

Terraform: mounted disk, certbot TLS


Main focus on this repository is about simplicity and readability. It is based on Terraform IaC only. The TLS certs are provided by hashicorp/terraform-provider-tls for the cluster. The TFE TLS certificate can be self-signed, tf-provider-tls, or certbot (Letsencrypt). The instances/hosts are configured through "user-data" scripts (bash) during the initial built-time. The "user-data" scripts are dynamically rendered (hashicorp/terraform-provider-template) based on variables.tf.



---

## Variable Argument Reference:

| Key | Description | Default |
| - | :- | :- |
| **Global Settings** |
| aws_region | (required) The AWS region to be used | eu-west-1 |
| name | (required) Environment name to be used as Tag  | none |
| server_count | (optional) Amount of cluster instances (odd number 1,3, max 5) | 3 |
| instance_type | (optional) Type of EC2 cluster instance | t2.small |
| server_name | (optional) Hostname prefix of the cluster instances | hc-stack-srv |
| root_block_device_size | (optional) Size of the root filesystem | 80 |
| auto_join_value | (optional) Server rejoin tag_value to identify cluster instances | joestack_hashistack_autojoin |
| dns_domain | (required) The Route53 Zone to assign DNS records to | hashidemos.io |
| key_name | (required) SSH key to be used to access the instances | joestack |
| whitelist_ip | (optional) The allowed ingress IP CIDR assigned to the ASGs | 0.0.0.0/0 |
| network_address_space | (optional) The CIDR to be used for the instances | 172.16.0.0/16 |
| create_root_ca | (optional) Create a self-signed root ca based on hashicorp/terraform-provider-tls | true |
| common_name | (optional) Common Name of the CA | hashistack |
| organization | (optional) Organization of the CA | joestack |
| **Vault Settings** |
| vault_enabled | (optional) Create a Vault cluster [true, false] | false |
| vault_version | (required if vault_enabled) The Vault version to be used [1.9.3, 1.9.3+ent] | 1.9.3 |
| vault_lic | (required if +ent) The Vault license in case of using Vault Enterprise | NULL |
| vault_tls_enabled | (optional) Using Vault with TLS enabled [true, false] | true |
| **Consul Settings** |
| consul_enabled | (optional) Create a Consul cluster [true, false] | false |
| consul_version | (required if consul_enabled) The Consul version to be used [1.13.3, 1.13.3+ent-1] | 1.13.3 |
| consul_lic | (required if +ent) The Consul license in case of using Consul Enterprise | NULL |
| consul_tls_enabled | (optional) Using Consul with TLS enabled [true, false] | true |
| **Nomad Settings** |
| nomad_enabled | (optional) Create a Nomad cluster [true, false] | false |
| nomad_version | (required if nomad_enabled) The Nomad version to be used [1.2.5, 1.2.5+ent] | 1.2.5 |
| nomad_lic | (required if +ent) The Nomad license in case of using Nomad Enterprise | NULL |
| nomad_bootstrap | (optional) Automatically bootrstrap the Nomad cluster [true, false] | false |
| datacenter | (optional) The name of the Datacenter | dc1 |
| region | (optional) The name of the region | global | 
| client | (optional) Install Nomad clients/worker as well [true, false] | true |
| client_count | (optional) The amount of Nomad clients | 3 |
| client_name | (optional) Hostname prefix of Nomad clients | nmd-worker |
| **Terraform Settings** |
| terraform_enabled | (optional) Create a Terraform Enterprise instance [true, false] | false |
| tfe_lic | (required if terraform_enabled) The Terraform Enterprise license file. | NULL |
| tfe_auth_password | (optional) The initial authentication password. Will be created if NULL | NULL |
| tfe_enc_password | (optional) The encryption key to be used to encrypt state and db. Will be created if NULL | NULL |
| tfe_hostname | (optional) The hostname of the TFE instance | tfe-joestack |
| tfe_cert_provider | (optional) TLS Certificate options [self-signed, certbot, tf-tls-provider] | certbot |
| tfe_cert_email | (required if certbot) Certbot email address | none |
| tfe_auto_install | (optional) Automatically install TFE on instance [true, false] | true |

---
### Take a look at the **outputs** to find the IP addresses of the instances or the initial password to access Terraform.
---
