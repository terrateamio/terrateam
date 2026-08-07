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

variable "nlb-arn"{
  type = string
  description = "The ARN of the corresponding load balancer"
}

variable "name"{
  type = string
  description = "The name of the target group"
}

variable "lambda-arn" {
  type = string
  description = "The arn of the corresponding lambda function"
}

variable "lambda-name"{ 
  type = string
  description = "The name of the corresponding lambda function"
}

variable "target" {
  type = object({
    FQDN = string
    internal-port = number
    external-port = number
  })
  description = "The target to which the NLB should serve traffic"
}

variable "polling-schedule-expression"{
  type = string
  description = "A cron expression that determines how often the lambda function will execute per target group. For formatting information, see this guide: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#CronExpressions"
}