// TLS Certificates
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

  validity_period_hours = 720
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

###################
## Cluster Nodes ##
###################
resource "tls_private_key" "server-node" {
  count       = local.server_count
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "server-node" {
  count           = local.server_count
  private_key_pem = tls_private_key.server-node[count.index].private_key_pem
  subject {
    #common_name  = "${var.server_name}-0${count.index +1}.${var.dns_domain}"
    common_name  = var.common_name
    organization = var.organization
  }

  dns_names = concat(local.fqdn_tls, local.consul_fqdn_tls)

  ip_addresses = [
    "127.0.0.1"
  ]

}

resource "tls_locally_signed_cert" "server-node" {
  count              = local.server_count
  cert_request_pem   = tls_cert_request.server-node[count.index].cert_request_pem
  ca_private_key_pem = element(tls_private_key.ca.*.private_key_pem, count.index)
  ca_cert_pem        = element(tls_self_signed_cert.ca.*.cert_pem, count.index)

  validity_period_hours = 720
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

  validity_period_hours = 720
  allowed_uses = [
    "key_encipherment",
    "key_agreement",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}
