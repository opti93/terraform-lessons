variable "region" {
  description = "Please enter AWS region to deploy server"
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "Enter instance type"
  default     = "t2.micro"
}
