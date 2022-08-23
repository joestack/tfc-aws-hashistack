locals {
  nomad_apt   = length(split("+", var.nomad_version)) == 2 ? "nomad-enterprise" : "nomad"
  consul_apt  = length(split("+", var.consul_version)) == 2 ? "consul-enterprise" : "consul"
  vault_apt   = length(split("+", var.vault_version)) == 2 ? "vault-enterprise" : "vault"
  kms_key_id  = var.vault_enabled ? aws_kms_key.vault.0.key_id : "NULL"
  cert        = var.vault_tls_enabled ? tls_locally_signed_cert.vault.0.cert_pem : "NULL"
  key         = var.vault_tls_enabled ? tls_private_key.vault.0.private_key_pem : "NULL"
  ca_cert     = var.vault_tls_enabled ? tls_private_key.ca.0.public_key_pem : "NULL"
  protocol    = var.vault_tls_enabled ? "https" : "http"
  tls_disable = var.vault_tls_enabled ? "false" : "true"
  #fqdn_server = [for o in aws_instance.server[*] : formatlist("%s.%s", o.tags["Name"], var.dns_domain)] # cyclic dependencies!
  #fqdn_tls    = [for i in range(1,4) : formatlist("%s%s.%s", "${var.server_name}-0", i, var.dns_domain)] # works but still too static
  fqdn_tls    = [for i in range(var.server_count) : format("%s-%02d.%s", var.server_name, i +1, var.dns_domain)]
}

data "template_file" "server" {
  count = var.server_count
  template = "${join("\n", tolist([
    file("${path.root}/templates/base.sh"),
    file("${path.root}/templates/server.sh")
  ]))}"
  vars = {
    server_count        = var.server_count
    data_dir            = var.data_dir
    datacenter          = var.datacenter
    region              = var.region
    autojoin_key        = var.autojoin_key
    autojoin_value      = var.autojoin_value
    #nomad_join          = var.tag_value
    node_name           = format("${var.server_name}-%02d", count.index +1)
    nomad_enabled       = var.nomad_enabled
    nomad_version       = var.nomad_version
    nomad_apt           = local.nomad_apt
    nomad_lic           = var.nomad_lic
    nomad_bootstrap     = var.nomad_bootstrap
    consul_enabled      = var.consul_enabled
    consul_version      = var.consul_version
    consul_apt          = local.consul_apt
    consul_lic          = var.consul_lic
    vault_enabled       = var.vault_enabled
    vault_version       = var.vault_version
    vault_apt           = local.vault_apt
    vault_lic           = var.vault_lic
    kms_key_id          = local.kms_key_id
    aws_region          = var.aws_region
    protocol            = local.protocol
    tls_disable         = local.tls_disable
    cert                = local.cert 
    key                 = local.key
    ca_cert             = local.ca_cert
    dns_domain          = var.dns_domain
  }
}

data "template_cloudinit_config" "server" {
  count = var.server_count
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = element(data.template_file.server.*.rendered, count.index)
  }
}

resource "aws_instance" "server" {
  count                       = var.server_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(aws_subnet.nomad_subnet.*.id, count.index)
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.primary.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.hc-stack-server.name

  tags = {
    Name     = format("${var.server_name}-%02d", count.index + 1)
    nomad_join  = var.tag_value
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  user_data = element(data.template_cloudinit_config.server.*.rendered, count.index)
}