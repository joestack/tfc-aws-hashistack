# tfc-aws-hashistack

This is a one-size-fits-all approach to setup Terraform Enterprise, Vault, Consul, Nomad or any combination of them.

Its behavor can be customized by changing/overriding the defaults in variables.tf

Vault: TLS encryption, auto-unseal, auto-join, raft-storage -> you can start with "vault operator init"

Consul: TLS encryption, gossip encryption, ACL bootstrapping 

Nomad: Auto bootstrapping, variable amount of workers (can be configured in variables.tf as well)

Terraform: mounted disk, certbot TLS


Main focus on this repository is about simplicity and readability. It is based on Terraform IaC only. The TLS certs are provided by hashicorp/terraform-provider-tls. The instances/hosts are configured through "user-data" scripts (bash) during the initial built-time. The "user-data" scripts are dynamically rendered (hashicorp/terraform-provider-template) based on variables.tf.



