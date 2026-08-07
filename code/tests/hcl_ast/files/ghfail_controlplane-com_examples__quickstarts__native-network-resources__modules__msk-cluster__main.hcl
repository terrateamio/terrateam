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

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc-cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.name-prefix}-vpc"
  }
}

data "aws_availability_zones" "availability-zones" {
  state = "available"
}

resource "aws_subnet" "subnet-0" {
  availability_zone = data.aws_availability_zones.availability-zones.names[0]
  cidr_block        = var.subnet-cidr-list[0]
  vpc_id            = aws_vpc.vpc.id
  tags = {
    Parent = var.name-prefix
    Name = "${var.name-prefix}-sn-0"
  }
}

resource "aws_subnet" "subnet-1" {
  availability_zone = data.aws_availability_zones.availability-zones.names[1]
  cidr_block        = var.subnet-cidr-list[1]
  vpc_id            = aws_vpc.vpc.id
  tags = {
    Parent = var.name-prefix
    Name = "${var.name-prefix}-sn-1"
  }
}

resource "aws_subnet" "subnet-2" {
  availability_zone = data.aws_availability_zones.availability-zones.names[2]
  cidr_block        = var.subnet-cidr-list[2]
  vpc_id            = aws_vpc.vpc.id
  tags = {
    Parent = var.name-prefix
    Name = "${var.name-prefix}-sn-2"
  }
}

resource "aws_security_group" "security-group" {
  vpc_id = aws_vpc.vpc.id
  name = "${var.name-prefix}-sg"
  tags = var.cluster-tags
  ingress {
    from_port = 9090
    protocol  = "tcp"
    to_port   = 9100
    cidr_blocks = [var.vpc-cidr]
  }
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_kms_key" "security-key" {
  description = "${var.name-prefix} security key"
}

resource "aws_cloudwatch_log_group" "cloudwatch-log-group" {
  name ="${var.name-prefix}-log-group"
}

resource "aws_msk_cluster" "msk-cluster" {
  cluster_name = var.name-prefix
  kafka_version = "2.8.1"
  number_of_broker_nodes = var.broker-count
  
  broker_node_group_info {
    client_subnets  = [
      aws_subnet.subnet-0.id,
      aws_subnet.subnet-1.id,
      aws_subnet.subnet-2.id
    ]
    ebs_volume_size = var.broker-storage-capacity
    instance_type   = var.broker-instance-type
    security_groups = [aws_security_group.security-group.id]
  }
  
  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.security-key.arn  
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }
  
  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled = true
        log_group = aws_cloudwatch_log_group.cloudwatch-log-group.name
      }
    }
  }
  
  tags = var.cluster-tags
  
}

output "vpc-id" {
  description = "The id of the VPC containing the MSK cluster"
  value = aws_vpc.vpc.id
}

output "subnet-ids" {
  description = "A list of the subnet ids for the MSK cluster"
  value = [aws_subnet.subnet-0.id, aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
}

output "security-group-id" {
  description = "The id of the security group created for the MSK cluster"
  value = aws_security_group.security-group.id
}

output "bootstrap-brokers" {
  value = aws_msk_cluster.msk-cluster.bootstrap_brokers_tls
  description = "A comma-delimited list of DNS names that can be used to connect to the cluster"
}

output "cluster-arn" {
  value = aws_msk_cluster.msk-cluster.arn
  description = "The arn of the MSK cluster"
}

output "cluster-name" {
  value = aws_msk_cluster.msk-cluster.cluster_name
  description = "The name of the MSK cluster"
}