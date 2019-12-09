variable "ingress_ports" {
  type        = list(string)
  description = "list of ingress ports"
  default     = [22, 443, 2299]
}

/**variable "aws_key" {
  description = "Reference to existing AWS ec2 keys. Nota that keys and instance must be in same region!"
  default     = "stenio-aws"
}*/

variable "instance_size" {
  description = "list of ingress ports"
  default     = "t2.micro"
}

variable "availability_zones" {
  description = "list of az"
  default     = ["us-east-1a", "us-east-1b"]
}

