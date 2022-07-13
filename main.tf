provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


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

resource "aws_route_table_association" "nomad-subnet" {
  count          = var.server_count
  subnet_id      = element(aws_subnet.nomad_subnet.*.id, count.index)
  route_table_id = aws_route_table.rtb.id
}


resource "aws_subnet" "nomad_subnet" {
  count                   = var.server_count
  vpc_id                  = aws_vpc.hashicorp_vpc.id
  cidr_block              = cidrsubnet(var.network_address_space, 8, count.index + 1)
  map_public_ip_on_launch = "true"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index) 

  tags = {
    Name = "${var.name}-subnet"
  }
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
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 4646
  to_port           = 4648
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "nomad-2" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 4646
  to_port           = 4648
  protocol          = "udp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "vault-1" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8200
  to_port           = 8202
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "vault-2" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8300
  to_port           = 8302
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "vault-3" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8300
  to_port           = 8302
  protocol          = "udp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "vault-4" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8400
  to_port           = 8400
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "consul-1" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8500
  to_port           = 8500
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "consul-2" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8600
  to_port           = 8600
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "consul-3" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 8600
  to_port           = 8600
  protocol          = "udp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "consul-4" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 20000
  to_port           = 29999
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}

resource "aws_security_group_rule" "consul-5" {
  security_group_id = aws_security_group.primary.id
  type              = "ingress"
  from_port         = 30000
  to_port           = 39999
  protocol          = "tcp"
  cidr_blocks       = [var.whitelist_ip]
}