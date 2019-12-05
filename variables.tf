variable "ingress_ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [22, 443, 2299]
}


variable "instance_size" {
  description = "list of ingress ports"
  default     = "t2.micro"
}
