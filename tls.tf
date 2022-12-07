### Root CA ###

resource "tls_private_key" "ca" {
  count       = var.create_root_ca ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "ca" {
  count             = var.create_root_ca ? 1 : 0
  private_key_pem   = tls_private_key.ca[count.index].private_key_pem
  is_ca_certificate = true

  validity_period_hours = 12
  allowed_uses = [
    "key_encipherment",
    "key_agreement",
    "digital_signature",
    "server_auth",
    "client_auth",
    "cert_signing",
  ]

  subject {
    common_name  = var.common_name
    organization = var.organization
  }
}


### Vault ###

resource "tls_private_key" "vault" {
  count       = var.vault_tls_enabled ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "vault" {
  count           = var.vault_tls_enabled ? 1 : 0
  private_key_pem = tls_private_key.vault[count.index].private_key_pem
  subject {
    common_name  = var.common_name
    organization = var.organization
  }

  dns_names = local.fqdn_tls

  # dns_names = [
  #   "*.${var.dns_domain}",
  #   "${var.dns_domain}",
  #   "${var.server_name}*"
  # ]


  ip_addresses = [
    "127.0.0.1"
  ]
}


resource "tls_locally_signed_cert" "vault" {
  count            = var.vault_tls_enabled ? 1 : 0
  cert_request_pem = tls_cert_request.vault[count.index].cert_request_pem

  ca_private_key_pem = tls_private_key.ca[count.index].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[count.index].cert_pem

  validity_period_hours = 12
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}


### Consul ###

resource "tls_private_key" "consul" {
  count       = var.consul_tls_enabled ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "consul" {
  count           = var.consul_tls_enabled ? 1 : 0
  private_key_pem = tls_private_key.consul[count.index].private_key_pem
  subject {
    common_name  = var.common_name
    organization = var.organization
  }

  dns_names = concat(local.fqdn_tls, local.consul_fqdn_tls)

  ip_addresses = [
    "127.0.0.1"
  ]
}


resource "tls_locally_signed_cert" "consul" {
  count            = var.consul_tls_enabled ? 1 : 0
  cert_request_pem = tls_cert_request.consul[count.index].cert_request_pem

  ca_private_key_pem = tls_private_key.ca[count.index].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[count.index].cert_pem

  validity_period_hours = 12
  allowed_uses = [
    "key_encipherment",
    "key_agreement",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

### TFE ###

resource "tls_private_key" "tfe" {
  count       = var.terraform_enabled ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "tfe" {
  count           = var.terraform_enabled ? 1 : 0
  private_key_pem = tls_private_key.tfe[count.index].private_key_pem
  subject {
    common_name  = var.common_name
    organization = var.organization
  }

  dns_names = [
    "${var.tfe_hostname}.${var.dns_domain}"
  ]

  ip_addresses = [
    "127.0.0.1"
  ]
}


resource "tls_locally_signed_cert" "tfe" {
  count            = var.terraform_enabled ? 1 : 0
  cert_request_pem = tls_cert_request.tfe[count.index].cert_request_pem

  ca_private_key_pem = tls_private_key.ca[count.index].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[count.index].cert_pem

  validity_period_hours = 360
  allowed_uses = [
    "key_encipherment",
    "key_agreement",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}


##
## TODO: ADD COUNT

data "aws_route53_zone" "selected" {
  name         = "${var.dns_domain}."
  private_zone = false
}


resource "aws_route53_record" "server" {
  count   = var.server_count
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = lookup(aws_instance.server.*.tags[count.index], "Name")
  type    = "A"
  ttl     = "300"
  records = [element(aws_instance.server.*.public_ip, count.index)]
}

resource "aws_route53_record" "tfe" {
  count   = var.terraform_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = lookup(aws_instance.tfe.*.tags[count.index], "Name")
  #name    = "tfe.${var.dns_domain}"
  type    = "A"
  ttl     = "300"
  records = [element(aws_instance.tfe.*.public_ip, count.index)]
}