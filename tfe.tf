# locals are used to add a little more magic, dynamic, or circumstances to the vars 
# used by the template data source to render the user_data scripts
locals {
  tfe_enc_password  = var.tfe_enc_password != "NULL" ? var.tfe_enc_password : random_id.tfe_enc_password.id
  tfe_auth_password = var.tfe_auth_password != "NULL" ? var.tfe_auth_password : random_pet.tfe_auth_password.id
}

data "template_file" "tfe" {
  count = var.terraform_enabled ? 1 : 0
  template = (join("\n", tolist([
    file("${path.root}/templates/base.sh"),
    file("${path.root}/templates/tfe.sh")
  ])))
  vars = {
    node_name         = var.tfe_hostname
    tfe_fqdn          = "${var.tfe_hostname}.${var.dns_domain}"
    tfe_lic           = var.tfe_lic
    tfe_auth_password = local.tfe_auth_password
    tfe_tls_cert      = tls_locally_signed_cert.tfe.0.cert_pem
    tfe_tls_key       = tls_private_key.tfe.0.private_key_pem
    tfe_tls_ca        = tls_self_signed_cert.ca.0.cert_pem
    tfe_disk_path     = "/opt/tfe"
    tfe_enc_password  = local.tfe_enc_password
    tfe_cert_provider = var.tfe_cert_provider
    tfe_cert_email    = var.tfe_cert_email
    tfe_auto_install  = var.tfe_auto_install
    tfe_airgapped     = var.tfe_airgapped
  }
}

data "template_cloudinit_config" "tfe" {
  count         = var.terraform_enabled ? 1 : 0
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = element(data.template_file.tfe.*.rendered, count.index)
  }
}

resource "aws_instance" "tfe" {
  count                       = var.terraform_enabled ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  subnet_id                   = element(aws_subnet.hcstack_subnet.*.id, count.index)
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.tfe[count.index].id]
  key_name                    = var.key_name

  tags = {
    Name = var.tfe_hostname
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  user_data = element(data.template_cloudinit_config.tfe.*.rendered, count.index)

}

resource "random_id" "tfe_enc_password" {
  byte_length = 16
}

resource "random_pet" "tfe_auth_password" {
  length = 2
}

resource "aws_route53_record" "tfe" {
  count   = var.terraform_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = lookup(aws_instance.tfe.*.tags[count.index], "Name")
  type    = "A"
  ttl     = "300"
  records = [element(aws_instance.tfe.*.public_ip, count.index)]
}