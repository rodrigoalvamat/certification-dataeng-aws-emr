// Cluster VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = "${var.namespace}-${var.project}-${var.stage}-vpc"

  cidr                 = "10.0.0.0/16"
  azs                  = var.availability_zones
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    category                                 = "network",
    resource                                 = "vpc",
    for-use-with-amazon-emr-managed-policies = true
  })
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = module.vpc.vpc_id

  tags = merge(local.common_tags, {
    category                                 = "network",
    resource                                 = "internet-gateway",
    for-use-with-amazon-emr-managed-policies = true
  })
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]

  tags = merge(local.common_tags, {
    category                                 = "network",
    resource                                 = "nat-eip",
    for-use-with-amazon-emr-managed-policies = true
  })
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)

  tags = merge(local.common_tags, {
    category                                 = "network",
    resource                                 = "nat-gateway",
    for-use-with-amazon-emr-managed-policies = true
  })
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = module.vpc.vpc_id
  count                   = length(var.public_subnets)
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    category                                 = "network",
    resource                                 = "public-subnet",
    for-use-with-amazon-emr-managed-policies = true
  })
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = module.vpc.vpc_id
  count                   = length(var.private_subnets)
  cidr_block              = element(var.private_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    category                                 = "network",
    resource                                 = "private-subnet",
    for-use-with-amazon-emr-managed-policies = true
  })
}

resource "aws_route_table" "public" {
  vpc_id = module.vpc.vpc_id

  tags = merge(local.common_tags, {
    category                                 = "network",
    resource                                 = "public-route-table",
    for-use-with-amazon-emr-managed-policies = true
  })
}

resource "aws_route_table" "private" {
  vpc_id = module.vpc.vpc_id

  tags = merge(local.common_tags, {
    category                                 = "network",
    resource                                 = "private-route-table",
    for-use-with-amazon-emr-managed-policies = true
  })
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

// Spark security group
resource "aws_security_group" "security_group_spark" {
  description = "Allow Spark inbound traffic"
  name        = "${var.namespace}-${var.project}-${var.stage}-security-group"
  depends_on  = [module.vpc.vpc_id]

  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {
    category                                 = "network",
    resource                                 = "security-group",
    service                                  = "spark",
    for-use-with-amazon-emr-managed-policies = true
  })
}
