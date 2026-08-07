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

resource "aws_lb" "aws-nlb" {
  name = "${var.name-prefix}-nlb"
  internal = var.internal
  load_balancer_type = "network"
  subnets = var.subnet-ids
  tags = var.tags
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "aws-target-group" {
  for_each = var.targets
  name = "${var.name-prefix}-tg-${index(values(var.targets), each.value)}"
  port = each.value.internal-port
  target_type = "ip"
  protocol = "TCP"
  vpc_id = var.vpc-id
  tags = {
    Parent = var.name-prefix
    target-ip = each.value.ip-address
    target-internal-port = each.value.internal-port
    target-external-port = each.value.external-port
  }
}

resource "aws_lb_target_group_attachment" "aws-target-group-attachment" {
  for_each = aws_lb_target_group.aws-target-group
  target_group_arn = each.value.arn
  target_id = each.value.tags.target-ip
  port = each.value.tags.target-internal-port
}

resource "aws_lb_listener" "aws-lb-listener" {
  for_each = aws_lb_target_group.aws-target-group
  load_balancer_arn = aws_lb.aws-nlb.arn
  protocol = "TCP"
  port = each.value.tags.target-external-port
  tags = {
    Parent = var.name-prefix
  }
  default_action {
    type = "forward"
    target_group_arn = each.value.arn
  }
}

resource "aws_lb_target_group" "target-group-all" {
  count = (var.include-all-resources-in-one-target-group ? 1 : 0)
  name = "${var.name-prefix}-tg-all"
  port = values(var.targets)[0].internal-port
  vpc_id = var.vpc-id
  target_type = "ip"
  protocol = "TCP"
  tags = {
    Parent = var.name-prefix
  }
}

resource "aws_lb_listener" "lb-listener-all" {
  count = (var.include-all-resources-in-one-target-group ? 1 : 0)
  load_balancer_arn = aws_lb.aws-nlb.arn
  protocol = "TCP"
  port = values(var.targets)[0].internal-port
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target-group-all[0].arn
  }
  tags = {
    Parent = var.name-prefix
  }
}

resource "aws_lb_target_group_attachment" "lb-attachment-all" {
  for_each = {for k,t in var.targets : k => t if var.include-all-resources-in-one-target-group}
  target_group_arn = aws_lb_target_group.target-group-all[0].arn
  target_id = each.value.ip-address
  port = each.value.internal-port
}

output "nlb-dns-name" {
  value = aws_lb.aws-nlb.dns_name
}

output "nlb-arn" {
  value = aws_lb.aws-nlb.arn
}

output "zone-id" {
  value = aws_lb.aws-nlb.zone_id
}