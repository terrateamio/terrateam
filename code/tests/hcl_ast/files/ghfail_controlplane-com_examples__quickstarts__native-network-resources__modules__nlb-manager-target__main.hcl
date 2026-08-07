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

data "aws_lb" "nlb" {
  arn = var.nlb-arn
} 

resource "aws_lb_target_group" "aws-target-group" {
  name = var.name
  port = var.target.internal-port
  target_type = "ip"
  protocol = "TCP"
  vpc_id = data.aws_lb.nlb.vpc_id
  tags = {
    Parent = var.name
    FQDN = var.target.FQDN
  }
}

resource "aws_lb_listener" "aws-lb-listener" {
  load_balancer_arn = var.nlb-arn
  protocol = "TCP"
  port = var.target.external-port
  tags = {
    Parent = var.name
    FQDN = aws_lb_target_group.aws-target-group.tags.FQDN
    Name = "${var.name}-listener"
  }
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.aws-target-group.arn
  }
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name = "${var.name}-schedule-rule"
  schedule_expression = "${var.polling-schedule-expression}"
  tags = {
    Parent = var.name
    FQDN = var.target.FQDN
  }
}

resource "aws_lambda_permission" "schedule-permission"{
  action        = "lambda:InvokeFunction"
  function_name = var.lambda-name
  principal     = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.schedule.arn
}

resource "aws_cloudwatch_event_target" "schedule-target" {
  arn  = var.lambda-arn
  rule = aws_cloudwatch_event_rule.schedule.name
  input = <<EOF
    {
      "Name": "${var.name}",
      "TargetGroups": {
        "${aws_lb_target_group.aws-target-group.arn}": {
          "FQDN": "${var.target.FQDN}"
        }
      }
    }
  EOF
}

data "aws_lambda_invocation" "initial-target-setup" {
  function_name = var.lambda-name
  input = <<EOF
    {
      "Name": "${var.name}",
      "TargetGroups": {
        "${aws_lb_target_group.aws-target-group.arn}": {
          "FQDN": "${var.target.FQDN}"
        }
      }
    }
  EOF
}

output "aws-lb-target-group" {
  value = aws_lb_target_group.aws-target-group
}

output "aws-lb-listener" {
  value = aws_lb_listener.aws-lb-listener
}

output "initial-target-setup-result" {
  value = data.aws_lambda_invocation.initial-target-setup.result
}