

resource "openstack_compute_instance_v2" "machine" {
  count           = "${var.count}" 
  name            = "${format("%s-%04d", "${var.prefix}", count.index+1)}"
  region = "SBG1"
  image_name      = "Ubuntu 20.04"
  flavor_name     = "${var.flavor}"
  key_pair = "dsa"

  network {
    name        = "Ext-Net"
  }
}

variable "flavor" {}

output "ip_addresses" {
  value = "${join("\n", openstack_compute_instance_v2.machine.*.access_ip_v4)}"
}
