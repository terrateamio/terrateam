#
# Set up wireguard peer connections between nodes in each region
#

resource "null_resource" "ingress-node" {

  # Set ingress node as wireguard client peer of egress node
  provisioner "remote-exec" {
    inline = [
      "sshpass -p\"${var.ingress_bastion_password}\" -- sudo -i set-wireguard-peer delete \"${var.egress_bastion_host}\"",
      "sshpass -p\"${var.ingress_bastion_password}\" -- sudo -i set-wireguard-peer add \"${var.egress_bastion_host}\" \"${var.egress_bastion_admin}\" \"${var.egress_bastion_password}\" nat",
    ]
  }

  # Delete wireguard peering configuration
  provisioner "remote-exec" {
    when    = "destroy"
    inline = [
      "sshpass -p\"${var.ingress_bastion_password}\" -- sudo -i set-wireguard-peer delete \"${var.egress_bastion_host}\"",
    ]
  }

  triggers = {
    ingress_bastion_id = "${var.ingress_bastion_id}"
  }

  connection {
    type        = "ssh"
    user        = "${var.ingress_bastion_admin}"
    private_key = "${var.ingress_bastion_sshkey}"
    host        = "${var.ingress_bastion_host}"
  }

  depends_on = ["aws_route.ingress-egress-admin"]
}

resource "null_resource" "egress-node" {

  # Set egress node as wireguard server peer of ingress node
  provisioner "remote-exec" {
    inline = [
      "sshpass -p\"${var.egress_bastion_password}\" -- sudo -i set-wireguard-peer delete \"${var.ingress_bastion_host}\"",
      "sshpass -p\"${var.egress_bastion_password}\" -- sudo -i set-wireguard-peer add \"${var.ingress_bastion_host}\" \"${var.ingress_bastion_admin}\" \"${var.ingress_bastion_password}\"",
    ]
  }

  # Delete wireguard peering configuration
  provisioner "remote-exec" {
    when    = "destroy"
    inline = [
      "sshpass -p\"${var.egress_bastion_password}\" -- sudo -i set-wireguard-peer delete \"${var.ingress_bastion_host}\"",
    ]
  }

  triggers = {
    egress_bastion_id = "${var.egress_bastion_id}"
  }

  connection {
    type        = "ssh"
    user        = "${var.egress_bastion_admin}"
    private_key = "${var.egress_bastion_sshkey}"
    host        = "${var.egress_bastion_host}"
  }

  depends_on = ["aws_route.egress-ingress-admin"]
}