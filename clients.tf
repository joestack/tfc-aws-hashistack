data "template_file" "client" {
  count = var.client_count
  template = (join("\n", tolist([
    file("${path.root}/templates/base.sh"),
    file("${path.root}/templates/docker.sh"),
    file("${path.root}/templates/client.sh")
  ])))
  vars = {
    client_count    = var.client_count
    datacenter      = var.datacenter
    region          = var.region
    client          = var.client
    auto_join_value = var.auto_join_value
    node_name       = format("${var.client_name}-%02d", count.index + 1)
    nomad_enabled   = var.nomad_enabled
    nomad_version   = var.nomad_version
    nomad_apt       = local.nomad_apt
    consul_enabled  = var.consul_enabled
    consul_version  = var.consul_version
    consul_apt      = local.consul_apt
    consul_lic      = var.consul_lic
    consul_enabled  = var.consul_enabled
    nomad_enabled   = var.nomad_enabled
  }
}

data "template_cloudinit_config" "client" {
  count         = var.client_count
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = element(data.template_file.client.*.rendered, count.index)
  }
}

resource "aws_instance" "client" {
  count                       = var.nomad_enabled != "true" ? 0 : 1 * var.client_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(aws_subnet.hcstack_subnet.*.id, count.index)
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.primary.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.hc-stack-client.name

  tags = {
    Name      = format("${var.client_name}-%02d", count.index + 1)
    auto_join = var.auto_join_value
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  # ebs_block_device  {
  #   device_name           = "/dev/xvdd"
  #   volume_type           = "gp2"
  #   volume_size           = var.ebs_block_device_size
  #   delete_on_termination = "true"
  # }

  user_data = element(data.template_cloudinit_config.client.*.rendered, count.index)
}