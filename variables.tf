//GLOBAL SETTINGS NmdCnslVlt

variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "dns_domain" {
  description = "The Route53 Zone to assign DNS records to"
  default     = "joestack.xyz"
}

variable "instance_type" {
  description = "type of EC2 instance to provision (Server and Client Nodes)."
  default     = "t2.small"
}

variable "name" {
  description = "Environment name to pass to Name tag"
  default     = "joestack-hashistack"
}

variable "key_name" {
  description = "SSH key to connect to EC2 instances. Use the one that is already uploaded into your AWS region or add one to main.tf"
  default     = "joestack"
}

variable "whitelist_ip" {
  description = "opening up the ingress part of the ASGs"
  default = "0.0.0.0/0"
}

variable "network_address_space" {
  description = "The default CIDR to use"
  default     = "172.16.0.0/16"
}

variable "server_count" {
  description = "amount of nomad servers (odd number 1,3, max 5)"
  default     = "3"
}

variable "server_name" {
  default = "hc-stack-srv"
}

variable "root_block_device_size" {
  default = "80"
}

variable "data_dir" {
  description = "Nomad, Consul, Vault config option"
  default     = "/opt"
}


//NOMAD SETTINGS

variable "nomad_enabled" {
  default = "true"
}

variable "nomad_version" {
  description = "i.e. 1.2.5 or 1.2.5+ent"
  default = "1.2.5+ent"
}

variable "nomad_lic" {
  description = "You must be mad to assign sensitive values to a variable here! Use one of the other options"
  default = "NULL"
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
variable "tag_key" {
  description = "Server rejoin tag_key to identify servers within a region"
  default     = "js_nomad_tag"
}

variable "tag_value" {
  description = "Server rejoin tag_value to identify servers within a region"
  default     = "js_nomad_value"
}



//CONSUL SETTINGS

variable "consul_enabled" {
  default = "true"
}

variable "consul_version" {
  description = "i.e. 1.11.2 or 1.11.2+ent"
  default = "1.11.2+ent"
}

variable "consul_lic" {
  description = "You must be mad to assign sensitive values to a variable here! Use one of the other options"
  default = "NULL"
}


//VAULT SETTINGS

variable "vault_enabled" {
  default = "true"
}

variable "vault_version" {
  description = "i.e. 1.9.3 or 1.9.3+ent"
  default = "1.9.3"
}

variable "vault_lic" {
  description = "You must be mad to assign sensitive values to a variable here! Use one of the other options"
  default          = "NULL"
}

variable "vault_tls_enabled" {
  description = "If set to true you need to provide common name, organization, and dns_domain as well"
  default     = "true"
}

variable "common_name" {
  description = "Cert common name"
  default     = "vault"
}

variable "organization" {
  description = "Cert Organaization"
  default     = "joestack"
}
