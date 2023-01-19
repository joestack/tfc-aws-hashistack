# locals are used to add a little more magic, dynamic, or circumstances to the vars 
# used by the template data source to render the user_data scripts 
locals {
  vault_apt         = length(split("+", var.vault_version)) == 2 ? "vault-enterprise" : "vault"
  consul_apt        = length(split("+", var.consul_version)) == 2 ? "consul-enterprise" : "consul"
  nomad_apt         = length(split("+", var.nomad_version)) == 2 ? "nomad-enterprise" : "nomad"
  kms_key_id        = var.vault_enabled ? aws_kms_key.vault.0.key_id : "NULL"
  ca_cert           = var.create_root_ca ? tls_private_key.ca.0.public_key_pem : "NULL"
  fqdn_tls          = [for i in range(local.server_count) : format("%v-%02d.%v", var.server_name, i + 1, var.dns_domain)]
  vault_protocol    = var.vault_tls_enabled ? "https" : "http"
  vault_tls_disable = var.vault_tls_enabled ? "false" : "true"
  consul_fqdn_tls   = formatlist("server.%s.consul", [var.datacenter])
  server_ca          = var.consul_tls_enabled ? tls_self_signed_cert.ca.0.cert_pem : "NULL"
  consul_gossip_key = random_id.gossip.b64_std
  consul_protocol   = var.consul_tls_enabled ? "https" : "http"
  consul_init_token = random_uuid.consul_init_token.id
  server_count      = anytrue([var.vault_enabled, var.consul_enabled, var.nomad_enabled]) ? var.server_count : 0
}

data "template_file" "server" {
  count = local.server_count
  template = (join("\n", tolist([
    file("${path.root}/templates/base.sh"),
    file("${path.root}/templates/server.sh")
  ])))
  vars = {
    server_count      = local.server_count
    aws_region        = var.aws_region
    datacenter        = var.datacenter
    region            = var.region
    auto_join_value   = var.auto_join_value
    node_name         = format("${var.server_name}-%02d", count.index + 1)
    ca_cert           = local.ca_cert
    server_cert       = tls_locally_signed_cert.server-node[count.index].cert_pem
    server_key        = tls_private_key.server-node[count.index].private_key_pem
    server_ca         = local.server_ca
    dns_domain        = var.dns_domain
    vault_enabled     = var.vault_enabled
    vault_version     = var.vault_version
    vault_apt         = local.vault_apt
    vault_lic         = var.vault_lic
    kms_key_id        = local.kms_key_id
    vault_protocol    = local.vault_protocol
    vault_tls_disable = local.vault_tls_disable
    consul_enabled    = var.consul_enabled
    consul_version    = var.consul_version
    consul_apt        = local.consul_apt
    consul_lic        = var.consul_lic
    consul_gossip_key = local.consul_gossip_key
    consul_protocol   = local.consul_protocol
    consul_env_addr   = upper(local.consul_protocol)
    consul_init_token = local.consul_init_token
    nomad_enabled     = var.nomad_enabled
    nomad_version     = var.nomad_version
    nomad_apt         = local.nomad_apt
    nomad_lic         = var.nomad_lic
    nomad_bootstrap   = var.nomad_bootstrap
  }
}

data "template_cloudinit_config" "server" {
  count         = local.server_count
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = element(data.template_file.server.*.rendered, count.index)
  }
}

resource "aws_instance" "server" {
  count                       = local.server_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(aws_subnet.hcstack_subnet.*.id, count.index)
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.primary.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.hc-stack-server.name

  tags = {
    Name      = format("${var.server_name}-%02d", count.index + 1)
    auto_join = var.auto_join_value
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  user_data = element(data.template_cloudinit_config.server.*.rendered, count.index)
}

resource "random_id" "gossip" {
  byte_length = 32
}

resource "random_uuid" "consul_init_token" {
}

resource "aws_route53_record" "server" {
  count   = local.server_count
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = lookup(aws_instance.server.*.tags[count.index], "Name")
  type    = "A"
  ttl     = "300"
  records = [element(aws_instance.server.*.public_ip, count.index)]
}