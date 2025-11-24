variable "instance_type" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "tag" {
  type = string
}

variable "shutdown" {
  type    = bool
  default = false
}