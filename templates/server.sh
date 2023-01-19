#!/bin/bash

########################
###   COMMON BLOCK   ###
########################
common() {
sudo echo "${server_cert}" > /etc/ssl/certs/hashistack_fullchain.pem
sudo echo "${server_key}" > /etc/ssl/certs/hashistack_privkey.key
sudo echo "${server_ca}" > /etc/ssl/certs/hashistack_ca.pem
}

########################
###    VAULT BLOCK   ###
########################
install_vault_apt() {

sudo apt-get -y install ${vault_apt}=${vault_version}
sudo echo ${vault_lic} > /opt/vault/license.hclic
sudo chown -R vault:vault /opt/vault/

sudo chown -R vault:vault /opt/vault/

sudo tee /etc/vault.d/vault.hcl > /dev/null <<EOF
# Full configuration options can be found at https://www.vaultproject.io/docs/configuration
listener "tcp" {
    address = "0.0.0.0:8200"
    cluster_address= "0.0.0.0:8201"
    tls_cert_file = "/etc/ssl/certs/hashistack_fullchain.pem"
    tls_key_file  = "/etc/ssl/certs/hashistack_privkey.key"
    #tls_client_ca_file = "/etc/vault.d/hashistack_ca.pem"
    tls_disable = "${vault_tls_disable}"
}
storage "raft" {
    path = "/opt/vault/data"
    node_id = "${node_name}"
    retry_join {
        leader_tls_servername = "${node_name}.${dns_domain}"
        auto_join = "provider=aws tag_key=auto_join tag_value=${auto_join_value}"
    }
}
seal "awskms" {
  region     = "${aws_region}"
  kms_key_id = "${kms_key_id}"
}
ui = true
license_path = "/opt/vault/license.hclic"
disable_mlock = true
#cluster_addr = "https://$(private_ip):8201"
#cluster_addr = "https://${node_name}.${dns_domain}:8201"
#api_addr = "https://${node_name}.${dns_domain}:8200"
cluster_addr = "${vault_protocol}://${node_name}.${dns_domain}:8201"
api_addr = "${vault_protocol}://${node_name}.${dns_domain}:8200"
EOF

sudo tee /etc/vault.d/vault.conf > /dev/null <<ENVVARS
#FLAGS=-dev -dev-ha -dev-transactional -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200
FLAGS=
ENVVARS

sudo chown -R vault:vault /etc/vault.d/

sudo tee /etc/profile.d/vault.sh > /dev/null <<PROFILE
export VAULT_ADDR=${vault_protocol}://127.0.0.1:8200
export VAULT_TOKEN=
PROFILE

#sudo setcap cap_ipc_lock=+ep /usr/bin/vault

sudo tee /etc/systemd/system/vault.service > /dev/null <<EOF
[Unit]
Description=Vault Agent
#Requires=consul-online.target
#After=consul-online.target
[Service]
Restart=on-failure
EnvironmentFile=/etc/vault.d/vault.conf
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/bin/vault
ExecStart=/usr/bin/vault server -config /etc/vault.d \$FLAGS
ExecReload=/bin/kill -HUP \$MAINPID
KillSignal=SIGTERM
User=vault
Group=vault
LimitMEMLOCK=infinity
[Install]
WantedBy=multi-user.target
EOF

systemctl enable vault
systemctl start vault
#vault operator init
}




########################
###   CONSUL BLOCK   ###
########################
install_consul_apt() {

sudo apt-get install -y ${consul_apt}=${consul_version}
sudo echo ${consul_lic} > /opt/consul/license.hclic
sudo chown -R consul:consul /opt/consul/


sudo tee /etc/consul.d/consul.hcl > /dev/null <<EOF
data_dir         = "/opt/consul/"
server           = true
license_path     = "/opt/consul/license.hclic"
bootstrap_expect = ${server_count}
advertise_addr   = "$(private_ip)"
bind_addr        = "$(private_ip)"
client_addr      = "0.0.0.0"
#ui               = true
datacenter       = "${datacenter}"
retry_join       = ["provider=aws tag_key=auto_join tag_value=${auto_join_value}"]
retry_max        = 10
retry_interval   = "15s"

ui_config = {
  enabled = true
}

encrypt = "${consul_gossip_key}"

acl = {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
  tokens {
    initial_management = "${consul_init_token}"
  }
}

auto_encrypt {
  allow_tls = true
}

ports = {
  https = 8501
  grpc = 8502
  grpc_tls = 8503
}

tls {
  defaults {
    key_file = "/etc/ssl/certs/hashistack_privkey.key"
    cert_file = "/etc/ssl/certs/hashistack_fullchain.pem"
    ca_file = "/etc/ssl/certs/hashistack_ca.pem"
    verify_incoming = true
    verify_outgoing = true
  }

  internal_rpc {
    verify_server_hostname = true
  }
}

EOF

echo "Consul ENV "
sudo tee /etc/consul.d/consul.conf > /dev/null <<ENVVARS
FLAGS=-ui -client 0.0.0.0
CONSUL_${consul_env_addr}_ADDR=${consul_protocol}://127.0.0.1:8500
ENVVARS

sudo chown -R consul:consul /etc/consul.d/

echo "--> Writing profile"
sudo tee /etc/profile.d/consul.sh > /dev/null <<EOF
export CONSUL_${consul_env_addr}_ADDR=${consul_protocol}://127.0.0.1:8500
export CONSUL_HTTP_TOKEN=${consul_init_token}
EOF

source /etc/profile.d/consul.sh

echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/consul.service > /dev/null <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl
[Service]
User=consul
Group=consul
EnvironmentFile=/etc/consul.d/consul.conf
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/ \$FLAGS
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

echo "--> Starting consul"
sudo systemctl enable consul
sudo systemctl start consul
sleep 2

}

########################
###    NOMAD BLOCK   ###
########################
install_nomad_apt() {

sudo apt-get install -y ${nomad_apt}=${nomad_version}
sudo echo ${nomad_lic} > /opt/nomad/license.hclic
sudo chown -R nomad:nomad /opt/nomad/

sudo tee /etc/nomad.d/nomad.hcl > /dev/null <<EOF
name            = "${node_name}"
data_dir        = "/opt/nomad"
enable_debug    = "true"
bind_addr       = "0.0.0.0"
datacenter      = "${datacenter}"
region          = "${region}"
enable_syslog   = "true"
advertise {
  http = "$(private_ip):4646"
  rpc  = "$(private_ip):4647"
  serf = "$(private_ip):4648"
}
server {
  enabled          = "true"
  bootstrap_expect = ${server_count}
  license_path     = "/opt/nomad/license.hclic"
  server_join {
    retry_join = ["provider=aws tag_key=auto_join tag_value=${auto_join_value}"]
  }
}
acl {
  enabled = ${nomad_bootstrap}
}
plugin "raw_exec" {
  config {
    enabled = true
  }
}
autopilot {
    cleanup_dead_servers = true
    last_contact_threshold = "200ms"
    max_trailing_logs = 250
    server_stabilization_time = "10s"
    enable_redundancy_zones = false
    disable_upgrade_migration = false
    enable_custom_upgrades = false
}
EOF

echo "Nomad ENV "
sudo tee /etc/nomad.d/nomad.conf > /dev/null <<ENVVARS
NOMAD_ADDR=http://127.0.0.1:4646
ENVVARS

sudo chown -R nomad:nomad /etc/nomad.d/

echo "--> Writing profile"
sudo tee /etc/profile.d/nomad.sh > /dev/null <<"EOF"
#export NOMAD_ADDR="http://${node_name}.node.consul:4646"
export NOMAD_ADDR=http://127.0.0.1:4646
EOF

source /etc/profile.d/nomad.sh

echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/nomad.service > /dev/null <<EOF
[Unit]
Description=Nomad Server
Documentation=https://www.nomadproject.io/docs/
Requires=network-online.target
After=network-online.target
[Service]
User=nomad
Group=nomad
EnvironmentFile=/etc/nomad.d/nomad.conf
ExecStart=/usr/bin/nomad agent -config="/etc/nomad.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

echo "--> Starting nomad"
sudo systemctl enable nomad
sudo systemctl start nomad
sleep 2

echo "--> Waiting for all Nomad servers"
while [ "$(nomad server members 2>&1 | grep "alive" | wc -l)" -lt "${server_count}" ]; do
  sleep 5
done

echo "--> Waiting for Nomad leader"
while [ -z "$(curl -s http://localhost:4646/v1/status/leader)" ]; do
  sleep 5
done

echo "==> Nomad Server is Installed!"

}


add_consul_to_vault() {

sudo tee /etc/vault.d/service-consul.hcl > /dev/null <<EOF
service_registration "consul" {
  address = "localhost:8500"
}
EOF
sudo chown -R vault:vault /etc/vault.d/
}

additionals() {
sudo apt-get -y install consul-template jq
}

tutorial() {
  sudo tee ~/readme.txt > /dev/null <<EOF
  01: Initialize the Vault cluster
   vault operator init
  create some policies
  create a PKI secrets engine
  bootstrap consul
  create some policies
  create a consul secrets engine
  bootstrap nomad
  crete some policies
  create a nomad secrets engine
  adding consul service registry to Vault
  
  some basic nomad jobs
EOF
  
}

####################
#####   MAIN   #####
####################

common
[[ ${vault_enabled} = "true" ]] && install_vault_apt 
[[ ${consul_enabled} = "true" ]] && install_consul_apt
#[[ ${vault_enabled} = "true" ]] && add_consul_to_vault
[[ ${nomad_enabled} = "true" ]] && install_nomad_apt
additionals
tutorial