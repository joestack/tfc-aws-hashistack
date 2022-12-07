provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    #values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    #values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# data "aws_ami" "rhel" {
#   most_recent = true
#   owners      = ["309956199498"] // Red Hat's Account ID
#   filter {
#     name   = "name"
#     values = ["RHEL-8.5*"]
#   }
#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# data "aws_ami" "fedora" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["Fedora*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = [ "hvm"]
#   }

#   owners = ["125523088429"] 
# }


resource "aws_vpc" "hashicorp_vpc" {
  cidr_block           = var.network_address_space
  enable_dns_hostnames = "true"
  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hashicorp_vpc.id

}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.hashicorp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.name}-IGW"
  }
}

resource "aws_route_table_association" "hcstack-rtb" {
  count          = var.server_count
  subnet_id      = element(aws_subnet.hcstack_subnet.*.id, count.index)
  route_table_id = aws_route_table.rtb.id
}


resource "aws_subnet" "hcstack_subnet" {
  count                   = var.server_count
  vpc_id                  = aws_vpc.hashicorp_vpc.id
  cidr_block              = cidrsubnet(var.network_address_space, 8, count.index + 1)
  map_public_ip_on_launch = "true"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "${var.name}-subnet"
  }
}

resource "random_id" "gossip" {
  byte_length = 32
}

###############################
#######      ASG      #########

resource "aws_security_group" "primary" {
  name        = "${var.name}-primary-sg"
  description = "Primary ASG"
  vpc_id      = aws_vpc.hashicorp_vpc.id
}

resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "https" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.primary.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "nomad-1" {
  count             = var.nomad_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 4646
  to_port           = 4648
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "nomad-2" {
  count             = var.nomad_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 4646
  to_port           = 4648
  protocol          = "udp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "vault-1" {
  count             = var.vault_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8200
  to_port           = 8202
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "vault-2" {
  count             = var.vault_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8300
  to_port           = 8302
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "vault-3" {
  count             = var.vault_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8300
  to_port           = 8302
  protocol          = "udp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "vault-4" {
  count             = var.vault_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8400
  to_port           = 8400
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "consul-1" {
  count             = var.consul_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8500
  to_port           = 8500
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "consul-2" {
  count             = var.consul_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8600
  to_port           = 8600
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "consul-3" {
  count             = var.consul_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8600
  to_port           = 8600
  protocol          = "udp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "consul-4" {
  count             = var.consul_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 20000
  to_port           = 29999
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "consul-5" {
  count             = var.consul_enabled ? 1 : 0
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 30000
  to_port           = 39999
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

// TFE

resource "aws_security_group" "tfe" {
  count       = var.terraform_enabled ? 1 : 0
  name        = "${var.name}-tfe-sg"
  description = "TFE ASG"
  vpc_id      = aws_vpc.hashicorp_vpc.id
}

resource "aws_security_group_rule" "tfe-ssh" {
  count             = var.terraform_enabled ? 1 : 0
  security_group_id = aws_security_group.tfe[count.index].id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "tfe-http" {
  count             = var.terraform_enabled ? 1 : 0
  security_group_id = aws_security_group.tfe[count.index].id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "tfe-https" {
  count             = var.terraform_enabled ? 1 : 0
  security_group_id = aws_security_group.tfe[count.index].id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "tfe-admin" {
  count             = var.terraform_enabled ? 1 : 0
  security_group_id = aws_security_group.tfe[count.index].id
  type              = "ingress"
  from_port         = 8800
  to_port           = 8800
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "tfe-egress" {
  count             = var.terraform_enabled ? 1 : 0
  security_group_id = aws_security_group.tfe[count.index].id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

