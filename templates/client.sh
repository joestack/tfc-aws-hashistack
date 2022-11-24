#!/bin/bash

####################################
install_consul_apt() {
####################################
sudo apt-get install -y ${consul_apt}=${consul_version}
sudo echo ${consul_lic} > /opt/consul/license.hclic
sudo chown -R consul:consul /opt/consul/

sudo tee /etc/consul.d/consul.hcl > /dev/null <<EOF
#node_name   = "consul-client"
bind_addr    = "$(private_ip)"
server       = false
datacenter   = "${datacenter}"
data_dir     = "/opt/consul/"
log_level    = "INFO"
retry_join   = ["provider=aws tag_key=auto_join tag_value=${auto_join_value}"]
license_path     = "/opt/consul/license.hclic"

service {
  id      = "dns"
  name    = "dns"
  tags    = ["primary"]
  address = "localhost"
  port    = 8600
  check {
    id       = "dns"
    name     = "Consul DNS TCP on port 8600"
    tcp      = "localhost:8600"
    interval = "10s"
    timeout  = "1s"
  }
}

acl = {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
}
EOF

echo "Consul ENV "
sudo tee /etc/consul.d/consul.conf > /dev/null <<ENVVARS
FLAGS=-ui -client 0.0.0.0
CONSUL_HTTP_ADDR=http://127.0.0.1:8500
ENVVARS


echo "--> Writing profile"
sudo tee /etc/profile.d/consul.sh > /dev/null <<"EOF"
export CONSUL_HTTP_ADDR=http://127.0.0.1:8500
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

####################################
install_nomad_apt() {
####################################
sudo apt-get install -y ${nomad_apt}=${nomad_version}
sudo chown -R nomad:nomad /opt/nomad/

sudo tee /etc/nomad.d/nomad.hcl > /dev/null <<EOF
name            = "${node_name}"
data_dir        = "/opt/nomad"
enable_debug    = true
bind_addr       = "0.0.0.0"
datacenter      = "${datacenter}"
region          = "${region}"
enable_syslog   = "true"

advertise {
  http = "$(private_ip):4646"
  rpc  = "$(private_ip):4647"
  serf = "$(private_ip):4648"
}

client {
  enabled = ${client}
  server_join {
    retry_join = ["provider=aws tag_key=auto_join tag_value=${auto_join_value}"]
  }
  meta {
    "type" = "worker",
    "name" = "${node_name}"
  }
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

plugin "docker" {
  config {
    allow_privileged = false
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
Description=Nomad Client
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

echo "--> Waiting for Nomad leader"
while [ -z "$(curl -s http://localhost:4646/v1/status/leader)" ]; do
  sleep 5
done

echo "==> Nomad Client is Installed!"
}

additionals() {

sudo apt-get -y install consul-template vault

}

####################
#####   MAIN   #####
####################

[[ ${consul_enabled} = "true" ]] && install_consul_apt
[[ ${nomad_enabled} = "true" ]] && install_nomad_apt
additionals