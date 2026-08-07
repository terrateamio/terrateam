# Copyright 2022 Control Plan Corporation
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

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  required_version = ">= 1.1.0"
}

provider "aws" {
  region = var.aws-region
}


data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.name}-vpc"
  }
}

data "aws_msk_cluster" "msk-cluster" { 
  cluster_name = var.name
}

data "aws_msk_broker_nodes" "msk-broker-nodes" { 
  cluster_arn = data.aws_msk_cluster.msk-cluster.arn
}

data "aws_subnets" "subnets" {
  tags = {
    Parent = var.name
  }
}

data "aws_security_group" "msk-security-group" {
    name = "${var.name}-sg"
}

resource "aws_subnet" "bastion_subnet" {
  cidr_block = var.ecs-cidr
  vpc_id     = data.aws_vpc.vpc.id
  map_public_ip_on_launch = true
  tags = {
    Parent = "${var.name}-bastion"
    Name = "${var.name}-ecs-subnet"
  }
  
}

resource "aws_internet_gateway" "bastion-internet-gateway" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Parent = var.name
    Name = "${var.name}-ecs-internet-gateway"
  }
}

resource "aws_route_table" "bastion-route-table"{
  vpc_id = data.aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bastion-internet-gateway.id
  }
  
  tags = {
    Parent = var.name
    Name = "${var.name}-ecs-route-table"
  }
}

resource "aws_route_table_association" "ecs-route-table-association" {
  route_table_id = aws_route_table.bastion-route-table.id
  subnet_id = aws_subnet.bastion_subnet.id
}

resource "aws_security_group" "bastion-sg" {
  vpc_id = data.aws_vpc.vpc.id
  name = "${var.name}-bastion-sg"
  tags = {
    Parent = var.name
  }
  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amzn2" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners      = ["137112412989"]
}

resource "aws_instance" "bastion-instance" {
  ami = data.aws_ami.amzn2.id
  root_block_device {
    volume_size = 128
  }
  #key_name = var.bastion-key-name
  associate_public_ip_address = true
  instance_type = "t2.micro"
  subnet_id = aws_subnet.bastion_subnet.id
  vpc_security_group_ids = [aws_security_group.bastion-sg.id]
  
  tags = {
    Parent = var.name
    Name = "${var.name}-bastion"
  }
  
  user_data = templatefile("../msk-init-container/init-ec2-instance.tftpl", {
    broker-hosts = [for b in data.aws_msk_broker_nodes.msk-broker-nodes.node_info_list : element(tolist(b.endpoints), 0)]
  })
}

resource "time_sleep" "wait_for_bastion_instance_to_be_initialize" {
  depends_on = [aws_instance.bastion-instance]
  create_duration = "60s"
}

module "nlb" {
  vpc-id = data.aws_vpc.vpc.id
  source      = "../../modules/nlb"
  subnet-ids  = [for sid in data.aws_subnets.subnets.ids : sid]
  targets     = {
  for i, b in data.aws_msk_broker_nodes.msk-broker-nodes.node_info_list : i => {
    ip-address    = b.client_vpc_ip_address
    internal-port = 9094
    external-port = i + 9001
  }
  }
  name-prefix = var.name
}

module "dns" {
  depends_on = [time_sleep.wait_for_bastion_instance_to_be_initialize]
  source = "../../modules/dns"
  aliases = {for i, b in data.aws_msk_broker_nodes.msk-broker-nodes.node_info_list : i => {
    from-name = element(tolist(b.endpoints), 0)
    to-name = module.nlb.nlb-dns-name
  }}
  nlb-zone-id = module.nlb.zone-id
  vpc-id = data.aws_vpc.vpc.id
}

module "endpoint-service" {
  source = "../../modules/endpoint-service"
  nlb-arn = module.nlb.nlb-arn
  name-prefix = var.name
}

output "init" {
  value = templatefile("../msk-init-container/init-ec2-instance.tftpl", {
    broker-hosts = [for b in data.aws_msk_broker_nodes.msk-broker-nodes.node_info_list : element(tolist(b.endpoints), 0)]
  })
}

## Using ecs/Fargate to configure the MSK cluster is not recommended, because it can 
## also be done via an ec2 instance, and because a bastion host is needed for 
## validation anyway.

#resource "aws_ecs_cluster" "msk-setup-cluster" {
#  name = "msk-setup-cluster"
#  tags = {
#    Parent = var.name
#  }
#}
#
#resource "aws_ecs_task_definition" "msk-setup-task" {
#  family = "msk-setup-task"
#  network_mode = "awsvpc"    
#  requires_compatibilities = ["FARGATE"]
#  cpu = 512
#  memory = 1024
#  runtime_platform {
#    operating_system_family = "LINUX"
#    cpu_architecture = "X86_64"
#  }
#  container_definitions = jsonencode([{
#    name = "msk-init-container"
#    image = "kylecupp/kafka-cli-toolbox"
#    essential = true
#    cpu: 512
#    memory = 1024
#    environment = [for i, b in data.aws_msk_broker_nodes.msk-broker-nodes.node_info_list : {
#      name = "CPLN_MSK_BROKER_${i}"
#      value = element(tolist(b.endpoints), 0)
#    }]
#  }])
#}
#
#resource "aws_ecs_service" "msk-setup-service" {
#  name = "${var.name}-msk-init-task"
#  cluster = aws_ecs_cluster.msk-setup-cluster.id
#  task_definition = aws_ecs_task_definition.msk-setup-task.arn
#  desired_count = 1
#  launch_type = "FARGATE"
#  network_configuration  {
#    subnets = [aws_subnet.ecs_subnet.id]
#    security_groups = [data.aws_security_group.msk-security-group.id]
#    assign_public_ip = true
#  }
#}