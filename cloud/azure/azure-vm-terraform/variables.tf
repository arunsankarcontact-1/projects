variable "location" {
  default = "centralus"
}

variable "vm_admin_user" {
  default = "azureuser"
}
variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default="ssh/id_rsa.pub"
}
