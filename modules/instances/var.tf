# variables for instances module

variable "name" {
  default = "server-ldap"
}

variable "name2" {
  default = "client-ldap"
}

variable "instance_count" {
  default = "1"
}

variable "disk_size" {
  default = "20"
}

variable "image_source" {
  default = "centos-7-v20200205"
}

variable "instance_typece" {
  default = "g1-small"
}

#For networking via output:
variable "subnet-1-name" {}

variable "network_name" {}

variable "google_compute_firewall_rules" {}
