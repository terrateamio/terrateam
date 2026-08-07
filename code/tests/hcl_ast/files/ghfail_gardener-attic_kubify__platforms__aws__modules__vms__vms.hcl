# Copyright (c) 2017 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



resource "local_file" "image"{
  count = 0
  filename = "image-${var.node_type}.txt"
  content = "${var.image_name}"
}

data "aws_ami" "image" {
  most_recent      = true
  owners = ["self", "amazon", "aws-marketplace"]

  filter {
    name   = "name"
    values = ["${var.image_name}-*"]
  }
}

module "storage" {
  source = "../../../../modules/variable"
  value = "${var.provide_storage ? 1 : 0}"
}

module "instance_profile" {
  source = "../../../../modules/variable"
  value = "${lookup(var.iaas_info,"${var.node_type}_instance_profile")}"
}

locals {
  toggle="${var.vm_version % 2}"
}

#resource "aws_ebs_volume" "nodes" {
#  count       = "${module.storage.value * var.node_count}"
#  availability_zone = "${lookup(var.iaas_info,"availability_zone")}"
#  size        = "${var.volume_size + local.toggle}"
#  tags {
#      Name    = "${var.prefix}-${var.node_type}-${count.index}"
#  }
#}

resource "aws_ebs_volume" "nodes" {
  count       = "${module.storage.value * var.node_count * (1- local.toggle)}"
  availability_zone = "${lookup(var.iaas_info,"availability_zone")}"
  size        = "${var.volume_size + local.toggle}"
  tags {
      Name    = "${var.prefix}-${var.node_type}-${count.index}"
  }
}
resource "aws_ebs_volume" "nodes_b" {
  count       = "${module.storage.value * var.node_count * local.toggle}"
  availability_zone = "${lookup(var.iaas_info,"availability_zone")}"
  size        = "${var.volume_size + local.toggle}"
  tags {
      Name    = "${var.prefix}-${var.node_type}-${count.index}"
  }
}

module "volumes" {
  source = "../../../../modules/condlist"
  #source = "../../../../modules/listvar"
  #value = "${aws_ebs_volume.nodes.*.id}"

  if = "${local.toggle}"
  then = "${aws_ebs_volume.nodes_b.*.id}"
  else = "${aws_ebs_volume.nodes.*.id}"
}

##########################################
# nodes
#

module "tags" {
  source = "../../../../modules/mapvar"
  value = {
      clustername = "${var.cluster_name}"
      clustertype = "${var.cluster_type}"
      kind        = "${var.node_type}"
  }
}

locals {
  tags = "${merge(module.tags.value, var.tags)}"
}

resource "aws_instance" "nodes" {
  count           = "${var.node_count}"
  instance_type   = "${element(module.roll.flavor_list, count.index)}"
  ami             = "${element(module.roll.image_list, count.index)}"
  key_name        = "${var.key}"
  subnet_id       = "${module.fips.value > count.index ? lookup(var.iaas_info,"public_subnet_id") : var.subnet_id}"
  # not sure why name is working -> id forces change
  vpc_security_group_ids = ["${var.security_group}"]
  availability_zone = "${lookup(var.iaas_info,"availability_zone")}"

  disable_api_termination = false
  source_dest_check  = false

  root_block_device {
    volume_size = "${var.root_volume_size}"
  }
  
  iam_instance_profile = "${module.instance_profile.value}"

  tags = "${merge(module.tags.value, var.tags, map("Name", "${var.prefix}-${var.node_type}-${count.index}"))}"

  user_data = "${lookup(module.roll.cloud_init_map,element(module.roll.cloud_init_list,count.index))}"
}

resource "aws_volume_attachment" "nodes" {
  count       = "${var.node_count * module.storage.value}"
  device_name = "/dev/sdb"
  volume_id   = "${element(module.volumes.value,count.index)}"
  instance_id = "${element(aws_instance.nodes.*.id,count.index)}"
  skip_destroy = true
}

module "nodes" {
  source = "../../../../modules/listvar"
  value = ["${aws_instance.nodes.*.id}"]
}
module "ips" {
  source = "../../../../modules/listvar"
  value = ["${aws_instance.nodes.*.private_ip}"]
}

output "ids" {
  value = ["${aws_instance.nodes.*.id}"]
}
output "ips" {
  value = ["${aws_instance.nodes.*.private_ip}"]
}
output "disk_vm_ips" {
  value = ["${aws_instance.nodes.*.private_ip}"]
}

output "count" {
  value = ["${var.node_count}"]
}
output "storage" {
  value = ["${module.storage.value}"]
}

output "short_user_data" {
  value = "true"
}


output "vm_info" {
  value = {
    cloud_init = "${var.cloud_init}"
    flavor = "${var.flavor_name}"
    keypair = "${var.key}"
    image = "${data.aws_ami.image.id}"
    subnetid = "${var.subnet_id}"
    security_group = "${var.security_group}"
    iam_profile = "${module.instance_profile.value}"
    root_volume_size = "${var.root_volume_size}"
    tags = "${jsonencode(local.tags)}"
  }
}
