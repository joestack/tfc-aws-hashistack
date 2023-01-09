//GLOBAL CLUSTER SETTINGS

variable "aws_region" {
  description = "The AWS region to be used"
}

variable "name" {
  description = "Environment name to be used as Tag"
}

variable "server_count" {
  description = "Amount of cluster instances (odd number 1,3, max 5)"
  default     = "3"
}

variable "instance_type" {
  description = "Type of EC2 cluster instance"
  default     = "t2.small"
}

variable "server_name" {
  default = "hc-stack-srv"
}

variable "root_block_device_size" {
  default = "80"
}

variable "auto_join_value" {
  description = "Server rejoin tag_value to identify cluster instances"
  default     = "joestack_hashistack_autojoin"
}

variable "dns_domain" {
  description = "The Route53 Zone to assign DNS records to"
}

variable "key_name" {
  description = "SSH key name to be used to access any instances. Use the one that already exist in your AWS region or keep the default and assign the pub key to aws_hashistack_key variable"
  default     = "aws-hashistack-key"
}

variable "aws_hashistack_key" {
  description = "The public part of the SSH key to access any instance"
  default     = "NULL"
}

variable "whitelist_ip" {
  description = "The allowed ingress IP CIDR assigned to the ASGs"
  default     = "0.0.0.0/0"
}

variable "network_address_space" {
  description = "The default CIDR to use"
  default     = "172.16.0.0/16"
}

// GLOBAL CERT SETTINGS

variable "create_root_ca" {
  description = "Create a self-signed root ca based on hashicorp/terraform-provider-tls"
  default     = "true"
}

variable "common_name" {
  description = "Cert common name"
  default     = "hashistack"
}

variable "organization" {
  description = "Cert Organaization"
  default     = "joestack"
}

//VAULT SETTINGS

variable "vault_enabled" {
  default = "false"
}

variable "vault_version" {
  description = "i.e. 1.9.3 or 1.9.3+ent 'apt-cache show vault-enterprise'"
  default     = "1.9.3"
}

variable "vault_lic" {
  description = "You must be mad to assign sensitive values to a variable here! Use one of the other options"
  default     = "NULL"
}

variable "vault_tls_enabled" {
  description = "If set to true you need to provide common name, organization, and dns_domain as well"
  default     = "true"
}


//CONSUL SETTINGS

variable "consul_enabled" {
  default = "false"
}

variable "consul_version" {
  description = "i.e. 1.11.2 or 1.11.2+ent nowadays +ent-1 'apt-cache show consul-enterprise'"
  default     = "1.13.3"
}

variable "consul_lic" {
  description = "You must be mad to assign sensitive values to a variable here! Use one of the other options"
  default     = "NULL"
}

variable "consul_tls_enabled" {
  description = "If set to true you need to provide common name, organization, and dns_domain as well"
  default     = "true"
}

//variable "datatenter" is used from the NOMAD SETTINGS block

//NOMAD SETTINGS

variable "nomad_enabled" {
  default = "false"
}

variable "nomad_version" {
  description = "i.e. 1.2.5 or 1.2.5+ent 'apt-cache show nomad-enterprise'"
  default     = "1.2.5"
}

variable "nomad_lic" {
  description = "You must be mad to assign sensitive values to a variable here! Use one of the other options"
  default     = "NULL"
}

variable "nomad_bootstrap" {
  default = "false"
}

variable "datacenter" {
  default = "dc1"
}

variable "region" {
  default = "global"
}

variable "client" {
  description = "enable nomad client option?"
  default     = "true"
}
variable "client_count" {
  description = "amount of nomad clients?"
  default     = "3"
}
variable "client_name" {
  default = "nmd-worker"
}


// TERRAFORM

variable "terraform_enabled" {
  default = "false"
}

variable "tfe_airgapped" {
  description = "[true or false] The value of tfe_lic has to be `base64 -w0 ` encoded if set to true"
  default     = "false"
}

variable "tfe_lic" {
  description = "You must be mad to assign sensitive values to a variable here! Use one of the other options"
  default     = "NULL"
}

variable "tfe_auth_password" {
  description = "The initial password to access the TFE app on port 8800. If not specified, a random one will be created"
  default     = "NULL"
}

variable "tfe_enc_password" {
  description = "If not specified, a random one will be created"
  default     = "NULL"
}

variable "tfe_hostname" {
  default = "tfe-joestack"
}

variable "tfe_cert_provider" {
  description = "TLS cert option [self-signed,certbot,tf-tls-provider]"
  default     = "certbot"
}

variable "tfe_cert_email" {
  description = "mandatory in case of using certbot"
}

variable "tfe_auto_install" {
  description = "run the tfe install.sh directly by the user-data script. You can run is manually if set to false"
  default     = "true"
}