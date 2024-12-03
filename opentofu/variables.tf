variable "libvirt_storage_pool" {
  description = "Path to the libvirt storage pool"
  default     = "default"
}

variable "ubuntu_base_image_url" {
  description = "URL for the Ubuntu 22.04 base image"
  default     = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}

variable "vm_names" {
  description = "List of VM hostnames"
  default     = ["ubuntu1", "ubuntu2"]
}
