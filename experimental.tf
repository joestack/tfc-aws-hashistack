## Development section ##
# injecting the initial Vault root token as secret zero into a TFC Workspace acting as secure K/V store
#
# Yes you are right! It is not the best methodoligy to store sensitive data into a TFC workspace. But it is the only one available without introducing further tooling.
# I want to be able to deploy the entire environment in a programmatic fashion therefore I need programmatic access to Vault's ROOT_TOKEN!
# The access to these sensitive data is at least encrypted and access controlled. 
#
# vault_init= true to enable
# tfc_var_set is currently unused
# tfc_workspace= name of the workspace to be created if it doesn't already exist and to store the data in
# tfc_token= TFC token to be used to authorize the creation of that workspace and variable injection
# tfc_address= your Terraform endpoint usually app.terraform.io 
# tfc_org= your TF Org to be used 



variable "vault_init" {
  description = "auto unseal the cluster and store the root_token into a TF Var-Set"
  default     = "false"
} 

variable "tfc_var_set" {
  description  = "The name of the Var-Set to be used to store the initial secret zero"
  default      = "NULL"
}

variable "tfc_workspace" {
  default     = "NULL"
}

variable "tfc_token" {
  default     = "NULL"
}

variable "tfc_address" {
  default     = "app.terraform.io"
}

variable "tfc_org" {
  default     = "NULL" 
}