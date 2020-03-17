variable "vault_license" {
}

variable "vault_zip_url" {
  default = "https://releases.hashicorp.com/vault/1.3.0+ent/vault_1.3.0+ent_linux_amd64.zip"
}
variable "aws_key" {
  description = "Reference to existing AWS ec2 keys. Nota that keys and instance must be in same region!"
  default     = "stenio-aws"
}

variable "db_user" {
  description = "MySQL user for dynamic creds test"
  default = "vault"
}
variable "db_password" {
  description = "MySQL Password for dynamic creds test"
}
variable "aws_az" {
  description = "AWS az"
  default = "us-east-1b"
}
variable "aws_instance_type" {
  description = "type of EC2 instance to provision."
  default = "t2.micro"
}

variable "owner" {
  description = "name of owner"
  default = "stenio_ferreira2"
}

variable "ttl" {
  description = "metadata"
  default = "24"
}

variable "aws_ami_id" {
  default = "ami-000b3a073fc20e415"
}

### GCP

variable "gcp_zone" {
  description = "GCP zone, e.g. us-east1-a"
  default = "us-east1-b"
}

variable "gcp_machine_type" {
  description = "GCP machine type"
  default = "n1-standard-1"
}

variable "image" {
  description = "image to build instance from"
  default = "gce-uefi-images/ubuntu-1804-lts"
}