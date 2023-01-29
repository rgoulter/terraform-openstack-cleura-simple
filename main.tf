terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.49.0"
    }
  }
}

provider "openstack" {}

# Variables

variable "default_user_name" {
  description = "the name of the default user"
  type        = string
  default     = "debian"
}

variable "allow_ssh_access_cidr" {
  description = "the CIDR to allow SSH access to. Defaults to 0.0.0.0/0 (unrestricted)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_public_key" {
  description = "the SSH public key used to access the VM"
  type        = string
  default     = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
}

variable "instance_name" {
  description = "the name of the VM"
  type        = string
  default     = "debian"
}

# OpenStack Server flavor & image

data "openstack_compute_flavor_v2" "self" {
  name = "1C-2GB-20GB"
}

data "openstack_images_image_v2" "debian" {
  name        = "Debian 11"
  most_recent = true
}

# Networking

data "openstack_networking_network_v2" "ext" {
  name = "ext-net"
}

resource "openstack_networking_network_v2" "self" {
  name           = "terraform_vm_network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "self" {
  name       = "terraform_vm_subnet"
  network_id = openstack_networking_network_v2.self.id
  cidr       = "192.168.199.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "self" {
  name                = "terraform_vm_router"
  external_network_id = data.openstack_networking_network_v2.ext.id
}

resource "openstack_networking_router_interface_v2" "self" {
  router_id = openstack_networking_router_v2.self.id
  subnet_id = openstack_networking_subnet_v2.self.id
}

resource "openstack_networking_floatingip_v2" "self" {
  pool = data.openstack_networking_network_v2.ext.name
}

# Security

resource "openstack_compute_secgroup_v2" "allow_ssh" {
  name        = "allow_ssh"
  description = "allow SSH from the given CIDR"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = var.allow_ssh_access_cidr
  }
}

resource "openstack_compute_keypair_v2" "self" {
  name       = "terraform_keypair"
  public_key = var.ssh_public_key
}

# Instance

resource "openstack_compute_instance_v2" "debian" {
  name            = var.instance_name
  flavor_id       = data.openstack_compute_flavor_v2.self.id
  key_pair        = openstack_compute_keypair_v2.self.name
  security_groups = [openstack_compute_secgroup_v2.allow_ssh.name]
  user_data       = <<-USER
  #cloud-config
  system_info:
   default_user:
    name: ${var.default_user_name}
  chpasswd: { expire: false }
  ssh_pwauth: false
  package_upgrade: true
  USER

  block_device {
    uuid                  = data.openstack_images_image_v2.debian.id
    source_type           = "image"
    volume_size           = 20 # GBs
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}

resource "openstack_compute_floatingip_associate_v2" "self" {
  floating_ip = openstack_networking_floatingip_v2.self.address
  instance_id = openstack_compute_instance_v2.debian.id
}

# Outputs

output "ovh_image_id" {
  value = data.openstack_images_image_v2.debian.id
}

output "ext_net_id" {
  value = data.openstack_networking_network_v2.ext.id
}

output "compute_debian_ipv4" {
  value = openstack_networking_floatingip_v2.self.address
}
