#!/bin/bash

prerequisites_orig() {
sudo mkdir -p ${tfe_disk_path}
sudo echo "${tfe_lic}" > ${tfe_disk_path}/license.rli

curl https://install.terraform.io/ptfe/stable > ${tfe_disk_path}/install.sh
curl https://install.terraform.io/tfe/uninstall > ${tfe_disk_path}/uninstall.sh
}

prerequisites() {
mkdir -p ${tfe_disk_path}

if [[ ${tfe_airgapped} = "true" ]]
then
  echo "${tfe_lic}" | base64 -d > ${tfe_disk_path}/license.rli
else
  echo "${tfe_lic}" > ${tfe_disk_path}/license.rli
fi 

curl https://install.terraform.io/ptfe/stable > ${tfe_disk_path}/install.sh
curl https://install.terraform.io/tfe/uninstall > ${tfe_disk_path}/uninstall.sh
}

cert_is_tf_tls_provider() {
  # FIXME: need to be tested
  echo "${tfe_tls_cert}" > /etc/ssl/certs/tfe_fullchain.pem
  echo "${tfe_tls_key}" > /etc/ssl/certs/tfe_privkey.pem
  echo "${tfe_tls_ca}" > /etc/ssl/certs/tfe_ca.pem

  tee /etc/replicated.conf > /dev/null <<EOF
{
    "DaemonAuthenticationType":     "password",
    "DaemonAuthenticationPassword": "${tfe_auth_password}",
    "TlsBootstrapType":             "server-path",
    "TlsBootstrapHostname":         "${tfe_fqdn}",
    "TlsBootstrapCert":             "/etc/ssl/certs/tfe_fullchain.pem",
    "TlsBootstrapKey":              "/etc/ssl/certs/tfe_privkey.pem",
    "BypassPreflightChecks":        true,
    "ImportSettingsFrom":           "${tfe_disk_path}/application-settings.json",
    "LicenseFileLocation":          "${tfe_disk_path}/license.rli"
}
EOF

}

cert_is_certbot() {
  apt-get install -y certbot 
  certbot certonly --standalone --agree-tos -m ${tfe_cert_email} -d ${tfe_fqdn} -n

  tee /etc/replicated.conf > /dev/null <<EOF
{
    "DaemonAuthenticationType":     "password",
    "DaemonAuthenticationPassword": "${tfe_auth_password}",
    "TlsBootstrapType":             "server-path",
    "TlsBootstrapHostname":         "${tfe_fqdn}",
    "TlsBootstrapCert":             "/etc/letsencrypt/live/${tfe_fqdn}/fullchain.pem",
    "TlsBootstrapKey":              "/etc/letsencrypt/live/${tfe_fqdn}/privkey.pem",
    "BypassPreflightChecks":        true,
    "ImportSettingsFrom":           "${tfe_disk_path}/application-settings.json",
    "LicenseFileLocation":          "${tfe_disk_path}/license.rli"
}
EOF
}

cert_is_self_signed() {
  # FIXME: need to be tested
  tee /etc/replicated.conf > /dev/null <<EOF
{
    "DaemonAuthenticationType":     "password",
    "DaemonAuthenticationPassword": "${tfe_auth_password}",
    "TlsBootstrapType":             "self-signed",
    "TlsBootstrapHostname":         "${tfe_fqdn}",
    "TlsBootstrapCert":             "/etc/letsencrypt/live/${tfe_fqdn}/fullchain.pem",
    "TlsBootstrapKey":              "/etc/letsencrypt/live/${tfe_fqdn}/privkey.pem",
    "BypassPreflightChecks":        true,
    "ImportSettingsFrom":           "${tfe_disk_path}/application-settings.json",
    "LicenseFileLocation":          "${tfe_disk_path}/license.rli"
}
EOF
}



application_settings() {
tee ${tfe_disk_path}/application-settings.json > /dev/null <<EOF
{
  "aws_access_key_id": {},
  "aws_instance_profile": {},
  "aws_secret_access_key": {},
  "azure_account_key": {},
  "azure_account_name": {},
  "azure_client_id": {},
  "azure_container": {},
  "azure_endpoint": {},
  "azure_use_msi": {},
  "backup_token": {},
  "ca_certs": {},
  "capacity_concurrency": {
    "value": "10"
  },
  "capacity_cpus": {},
  "capacity_memory": {
    "value": "512"
  },
  "custom_image_tag": {
    "value": "hashicorp/build-worker:now"
  },
  "disk_path": {
    "value": "${tfe_disk_path}"
  },
  "enable_active_active": {},
  "enc_password": {
    "value": "${tfe_enc_password}"
  },
  "extern_vault_addr": {},
  "extern_vault_enable": {},
  "extern_vault_namespace": {},
  "extern_vault_path": {},
  "extern_vault_propagate": {},
  "extern_vault_role_id": {},
  "extern_vault_secret_id": {},
  "extern_vault_token_renew": {},
  "extra_no_proxy": {},
  "force_tls": {},
  "gcs_bucket": {},
  "gcs_credentials": {},
  "gcs_project": {},
  "hairpin_addressing": {},
  "hostname": {
    "value": "${tfe_fqdn}"
  },
  "iact_subnet_list": {},
  "iact_subnet_time_limit": {},
  "log_forwarding_config": {},
  "log_forwarding_enabled": {},
  "metrics_endpoint_enabled": {},
  "metrics_endpoint_port_http": {},
  "metrics_endpoint_port_https": {},
  "pg_dbname": {},
  "pg_extra_params": {},
  "pg_netloc": {},
  "pg_password": {},
  "pg_user": {},
  "placement": {},
  "production_type": {
    "value": "disk"
  },
  "redis_host": {},
  "redis_pass": {},
  "redis_port": {},
  "redis_use_password_auth": {},
  "redis_use_tls": {},
  "restrict_worker_metadata_access": {},
  "s3_bucket": {},
  "s3_endpoint": {},
  "s3_region": {},
  "s3_sse": {},
  "s3_sse_kms_key_id": {},
  "tbw_image": {
    "value": "default_image"
  },
  "tls_ciphers": {},
  "tls_vers": {
    "value": "tls_1_2_tls_1_3"
  }
}
EOF
}

run_installer() {
  cd ${tfe_disk_path}

  if [[ ${tfe_auto_install} = "true" ]]
  then
    sudo bash install.sh no-proxy private-address=$(private_ip) public-address=$(public_ip)
  else
    exit 0
  fi
  
}

####################
#####   MAIN   #####
####################
prerequisites
cert_is_${tfe_cert_provider}
application_settings
run_installer
