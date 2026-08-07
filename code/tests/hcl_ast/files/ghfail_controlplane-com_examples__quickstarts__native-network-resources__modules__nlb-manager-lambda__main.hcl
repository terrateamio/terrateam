# Copyright 2022 Control Plane Corporation
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

data "aws_vpc" "nlb-vpc" {
  id = var.vpc-id
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc-id]
  }
}

//Ensure the nlb-manager-role exists. The relevant role will not be duplicated.
module "nlb-manager-role" {
  source = "../nlb-manager-role"
}

resource "aws_subnet" "lambda-public-subnet" {
  vpc_id = var.vpc-id
  cidr_block = var.public-subnet-cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-lambda-public-subnet"
    Parent = var.name
  }
}

resource "aws_subnet" "lambda-private-subnets" {
  for_each = var.private-subnets
  cidr_block = each.value.CIDR
  vpc_id     = var.vpc-id
  availability_zone = each.value.availability-zone

  tags = {
    Name = "${var.name}-lambda-private-subnet-${each.key}"
    Parent = var.name
  }
}

resource "aws_eip" "nat-eip" {
  tags = {
    Name = "${var.name}-lambda-nat-gateway-eip"
    Parent = var.name
  }
}

resource "aws_nat_gateway" "lambda-nat-gateway" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id = aws_subnet.lambda-public-subnet.id

  tags = {
    Name = "${var.name}-lambda-nat-gateway"
    Parent = var.name
  }
}

resource "aws_route_table" "lambda-public-route-table" {
  vpc_id = var.vpc-id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.name}-lambda-public-route-table"
    Parent = var.name
  }
}

resource "aws_route_table" "lambda-private-route-table" {
  vpc_id = var.vpc-id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lambda-nat-gateway.id
  }
  
  tags = {
    Name = "${var.name}-lambda-private-route-table"
    Parent = var.name
  }
}

resource "aws_route_table_association" "lambda-public-route-table-association" {
  route_table_id = aws_route_table.lambda-public-route-table.id
  subnet_id = aws_subnet.lambda-public-subnet.id
}

resource "aws_route_table_association" "lambda-private-route-table-association" {
  for_each = aws_subnet.lambda-private-subnets
  route_table_id = aws_route_table.lambda-private-route-table.id
  subnet_id = each.value.id
}

resource "aws_security_group" "lambda-security-group" {
  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = [data.aws_vpc.nlb-vpc.cidr_block]
  }
  
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  tags = {
    Name = "${var.name}-lambda-security-group"
    Parent = var.name
  }
}

resource "aws_lambda_function" "nlb-manager-lambda" {
  function_name = var.name
  role = module.nlb-manager-role.arn
  runtime = "go1.x"
  handler = "main"
  vpc_config {
    security_group_ids = [aws_security_group.lambda-security-group.id]
    subnet_ids         = [for s in aws_subnet.lambda-private-subnets : s.id]
  }
  filename = "../utilities-go/nlb-dns-target-provider-lambda/main.zip"
}

output "lambda" {
  value = aws_lambda_function.nlb-manager-lambda
}