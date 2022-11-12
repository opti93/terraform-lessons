variable "region" {
  description = "Please enter AWS region to deploy server"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "Enter instance type"
  type        = string
  default     = "t2.small"
}

variable "allow_ports" {
  description = "List of Ports to open for server"
  type        = list(any)
  default     = ["80", "443", "22"]
}

variable "enable_detailed_monitoring" {
  type    = bool
  default = "false"
}
