terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Download Ubuntu base image jika masih belum ter-cache
resource "null_resource" "download_base_image" {
  provisioner "local-exec" {
    command = "wget -O /tmp/ubuntu-22.04.qcow2 ${var.ubuntu_base_image_url}"
  }
}

# Buat base volume untuk Ubuntu image
resource "libvirt_volume" "base_volume" {
  name   = "base.qcow2"
  source = "/tmp/ubuntu-22.04.qcow2"
  pool   = var.libvirt_storage_pool
  format = "qcow2"
  depends_on = [null_resource.download_base_image]
}

# Buat cloud-init disk untuk tiap VM
resource "libvirt_cloudinit_disk" "cloud_init_disk" {
  count          = length(var.vm_names)
  name           = "cloud-init-${count.index}.iso"
  user_data      = data.template_file.cloud_init_user_data[count.index].rendered
  network_config = data.template_file.network_config[count.index].rendered
  pool           = var.libvirt_storage_pool
}

# Buat VM disk volume dari base volume (5GB)
resource "libvirt_volume" "vm_disk" {
  count          = length(var.vm_names)
  name           = "ubuntu22-${count.index}.qcow2"
  base_volume_id = libvirt_volume.base_volume.id
  pool           = var.libvirt_storage_pool
  size           = 5368709120  # 5GB
}

# Render cloud-init user data for each VM
data "template_file" "cloud_init_user_data" {
  count    = length(var.vm_names)
  template = file("${path.module}/config/cloud_init.yml")
}

# Render network configuration for each VM
data "template_file" "network_config" {
  count    = length(var.vm_names)
  template = file("${path.module}/config/network_config.yml")
}

# Buat instance virtual machine
resource "libvirt_domain" "vm_instance" {
  count  = length(var.vm_names)
  name   = var.vm_names[count.index]
  memory = 1024  # Memory dalam MB
  vcpu   = 1     # Jumlah virtual CPU

  cloudinit = libvirt_cloudinit_disk.cloud_init_disk[count.index].id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
    hostname       = var.vm_names[count.index]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.vm_disk[count.index].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
