# Configure the Packet Provider
provider "packet" {
        auth_token = "${var.packet_api_key}"
}

# comment next three lines out if you wish to use a consistent project
resource "packet_project" "virl_project" {
        name = "virl server on packet"
}

resource "packet_ssh_key" "virlkey" {
        name = "virlkey"
        public_key = "${file("${var.ssh_private_key}.pub")}"
}

# 
resource "packet_device" "virl" {
        hostname = "${var.hostname}"
        plan = "${var.packet_machine_type}"
        facility = "${var.packet_location}"
        operating_system = "ubuntu_16_04_image"
        billing_cycle = "hourly"
        user_data = "${file("conf/${var.packet_location}-cloud.config")}"
        project_id = "${packet_project.virl_project.id}"
        depends_on = ["packet_ssh_key.virlkey","packet_project.virl_project"]

# Alternate project_id. If you use a consistent project defined in settings.tf, uncomment the two lines below. Remember to comment out the two lines above!
# Only have one project_id and depends_on defined at a time
        #project_id = "${var.packet_project_id}"
        #depends_on = ["packet_ssh_key.virlkey"]


  connection {
        type = "ssh"
        user = "root"
        port = 22
        timeout = "1200"
        private_key = "${file("${var.ssh_private_key}")}"
      }

   provisioner "remote-exec" {
      inline = [
    # dead mans timer
        "apt-get update",
        "apt-get install at time -y",
        "printf '/usr/bin/curl -H X-Auth-Token:${var.packet_api_key} -X DELETE https://api.packet.net/devices/${packet_device.virl.id}\n'>/etc/deadtimer",
        "sleep 3",
        "at now + ${var.dead_mans_timer} hours -f /etc/deadtimer"
    ]
    }
   provisioner "remote-exec" {
      inline = [
        "mkdir -p /etc/salt/minion.d",
        "mkdir -p /etc/salt/pki/minion",
        "dpkg --add-architecture i386"
    ]
    }
    provisioner "file" {
        source = "keys/"
        destination = "/etc/salt/pki/minion"
    }
    provisioner "file" {
        source = "conf/virl.ini"
        destination = "/etc/virl.ini"
    }
    provisioner "file" {
        source = "conf/extra.conf"
        destination = "/etc/salt/minion.d/extra.conf"
    }
    provisioner "file" {
        source = "conf/install_salt.sh"
        destination = "/root/install_salt.sh"
    }
    provisioner "file" {
        source = "conf/logging.conf"
        destination = "/etc/salt/minion.d/logging.conf"
    }
    provisioner "file" {
        source = "conf/apt.conf"
        destination = "/etc/apt/apt.conf"
    }
   provisioner "remote-exec" {
      inline = [
         "apt-get update -qq",
         "apt-get install crudini at -y",
         "service atd start",
         "printf '\nmaster: ${var.salt_master}\nid: ${var.salt_id}\nappend_domain: ${var.salt_domain}\n' >>/etc/salt/minion.d/extra.conf",
         "crudini --set /etc/virl.ini DEFAULT salt_id ${var.salt_id}",
         "crudini --set /etc/virl.ini DEFAULT salt_master ${var.salt_master}",
         "crudini --set /etc/virl.ini DEFAULT salt_domain ${var.salt_domain}",
         "crudini --set /etc/virl.ini DEFAULT guest_password ${var.guest_password}",
         "crudini --set /etc/virl.ini DEFAULT uwmadmin_password ${var.uwmadmin_password}",
         "crudini --set /etc/virl.ini DEFAULT password ${var.openstack_password}",
         "crudini --set /etc/virl.ini DEFAULT mysql_password ${var.mysql_password}",
         "crudini --set /etc/virl.ini DEFAULT keystone_service_token ${var.openstack_token}",
         "crudini --set /etc/virl.ini DEFAULT openvpn_enable ${var.openvpn_enable}",
         "crudini --set /etc/virl.ini DEFAULT hostname ${var.hostname}"
    ]
    }

/* comment multiline */
   provisioner "remote-exec" {
      inline = [

         "printf '\n\n\033[1;36m**** STARTING CONFIGURATION ****\033[0m\n'",
         "set -e",
         "set -x",
         "apt-get install openssh-server  python-dev ntp traceroute ntpdate zile curl traceroute unzip swig sshpass crudini debconf-utils dkms qemu-kvm gcc cpu-checker openssl apt-show-versions htop apache2 libapache2-mod-wsgi mtools socat crudini telnet -y",

         "printf '\n\n\033[1;36m**** INSTALLING SALTSTACK ****\033[0m\n'",
         "sleep 1 || true",
         "echo 'wget -O install_salt.sh https://bootstrap.saltstack.com'",
         "sleep 1 || true",
         "sh ./install_salt.sh -X -P stable",

         "printf '\n\n\033[1;36m**** INSTALLING VIRL BASICS ****\033[0m\n'",

         "printf '\n\n\033[1;36m**** Running common.users ****\033[0m\n'",
         "salt-call state.sls common.users",
         "salt-call grains.setval mitaka true",
         "salt-call grains.setval mysql_password ${var.mysql_password}",
         "salt-call file.write /etc/salt/minion.d/openstack.conf 'mysql.pass: ${var.mysql_password}'",

         "printf '\n\n\033[1;36m**** Copying VIRL keys ****\033[0m\n'",
         "salt-call state.sls virl.packet.keycopy",

         "printf '\n\n\033[1;36m**** Installing Ubuntu baseline packages ****\033[0m\n'",
         "salt-call state.sls common.ubuntu",

         "printf '\n\n\033[1;36m**** Configuring rc-local ****\033[0m\n'",
         "salt-call state.sls common.rc-local",

         "printf '\n\n\033[1;36m**** Creating VIRL vinstall ****\033[0m\n'",
         "salt-call state.sls virl.vinstall",

         "printf '\n\n\033[1;36m**** Configuring Salt ****\033[0m\n'",
         "/usr/local/bin/vinstall salt",

         "printf '\n\n\033[1;36m**** Configuring KVM ****\033[0m\n'",
         "salt-call state.sls common.kvm",

         "printf '\n\n\033[1;36m**** Configuring KSM ****\033[0m\n'",
         "salt-call state.sls common.ksm",

         "printf '\n\n\033[1;36m**** Configuring EFI BIOS ****\033[0m\n'",
         "salt-call state.sls virl.efibios",

         "printf '\n\n\033[1;36m**** Installing VIRL Scripts ****\033[0m\n'",
         "salt-call state.sls virl.scripts",

         "printf '\n\n\033[1;36m**** Installing VIRL pre-configuration script ****\033[0m\n'",
         "salt-call state.sls virl.virl_setup",

         "printf '\n\n\033[1;36m**** Installing / Configuring VIRL packages ****\033[0m\n'",
         "salt-call state.sls common.virl-sa",

         "printf '\n\n\033[1;36m**** Configuring VIRL Basics ****\033[0m\n'",
         "salt-call state.sls virl.basics",

         "printf '\n\n\033[1;36m**** INSTALLING OPENSTACK ****\033[0m\n'",
         "sleep 1 || true",

         "printf '\n\n\033[1;36m**** Installing MySQL ****\033[0m\n'",
         "salt-call state.sls openstack.mysql.install",

         "printf '\n\n\033[1;36m**** Creating OpenStack Accounts ****\033[0m\n'",
         "salt-call state.sls openstack.mysql.os_accounts",

         "printf '\n\n\033[1;36m**** Installing RabbitMQ ****\033[0m\n'",
         "salt-call state.sls openstack.rabbitmq",

         "printf '\n\n\033[1;36m**** Installing Keystone ****\033[0m\n'",
         "salt-call state.sls openstack.keystone.install",

         "printf '\n\n\033[1;36m**** Configuring Keystone ****\033[0m\n'",
         "salt-call state.sls openstack.keystone.setup",

         "printf '\n\n\033[1;36m**** Configuring Keystone End-points ****\033[0m\n'",
         "salt-call state.sls openstack.keystone.endpoint",

         "printf '\n\n\033[1;36m**** Configuring OpenStack Clients ****\033[0m\n'",
         "salt-call state.sls openstack.osclients",

         "printf '\n\n\033[1;36m**** Installing Glance ****\033[0m\n'",
         "salt-call state.sls openstack.glance",

         "printf '\n\n\033[1;36m**** Installing Neutron ****\033[0m\n'",
         "salt-call state.sls openstack.neutron",

         "printf '\n\n\033[1;36m**** Installing Nova ****\033[0m\n'",
         "salt-call state.sls openstack.nova",

         "printf '\n\n\033[1;36m**** Installing OpenStack Options ****\033[0m\n'",
         "salt-call state.sls openstack.options",     

         "printf '\n\n\033[1;36m**** Restarting OpenStack (1st-pass) ****\033[0m\n'",
         "salt-call state.sls openstack.restart",

         "printf '\n\n\033[1;36m**** INSTALLING VIRL ****\033[0m\n'",

         "printf '\n\n\033[1;36m**** Configuring Bridges ****\033[0m\n'",
         "salt-call state.sls common.bridge",

         "printf '\n\n\033[1;36m**** Restarting OpenStack (2nd-pass) ****\033[0m\n'",
         "salt-call state.sls openstack.restart",

         "printf '\n\n\033[1;36m**** Installing AutoNetkit ****\033[0m\n'",
         "salt-call state.sls virl.ank",  

         "printf '\n\n\033[1;36m**** Installing STD prerequisites ****\033[0m\n'",
         "salt-call state.sls virl.std.prereq",

         "printf '\n\n\033[1;36m**** Installing STD clients ****\033[0m\n'",
         "salt-call state.sls virl.std.clients",

         "printf '\n\n\033[1;36m**** Running common.ifb ****\033[0m\n'",
         "salt-call state.sls common.ifb",

         "printf '\n\n\033[1;36m**** Installing STD tap-counter ****\033[0m\n'",
         "salt-call state.sls virl.std.tap-counter",

         "printf '\n\n\033[1;36m**** Installing STD ****\033[0m\n'",
         "salt-call state.sls virl.std.install",

         "printf '\n\n\033[1;36m**** Restarting VIRL services ****\033[0m\n'",
         "service virl-std restart",
         "service virl-uwm restart",

         "printf '\n\n\033[1;36m**** Configuring OpenStack networks ****\033[0m\n'",
         "salt-call state.sls openstack.setup",

         "printf '\n\n\033[1;36m**** Installing VIRL guest user ****\033[0m\n'",
         "salt-call state.sls virl.guest",

         "printf '\n\n\033[1;36m**** Activating RAMdisk if enabled ****\033[0m\n'",
         "salt-call state.sls virl.ramdisk",

         "printf '\n\n\033[1;36m**** Installing Router VMs ****\033[0m\n'",
         "salt-call state.sls virl.routervms",

         "printf '\n\n\033[1;36m**** Installing OpenVPN ****\033[0m\n'",
         "salt-call state.sls virl.openvpn",
         "salt-call state.sls virl.openvpn.packet",
         "touch /var/local/virl/client.ovpn",

         "printf '\n\n\033[1;36m**** Setting Version Grain ****\033[0m\n'",
         "VERSION=`/usr/bin/salt-call pillar.get version:virl | cut -d':' -f2` && salt-call grains.setval virl_release $VERSION",

         "printf '\n\n\033[1;36m**** DONE ****'"

   ]
  }
    provisioner "local-exec" {
        command = "sftp -o 'IdentityFile=${var.ssh_private_key}' -o 'StrictHostKeyChecking=no' root@${packet_device.virl.network.0.address}:/var/local/virl/client.ovpn client.ovpn"
    }
#
   provisioner "remote-exec" {
      inline = [
        "sleep 5",
        "reboot"
        ]
        }
  }

#
