provider "aws" {
  #region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "init" {
  template = file("init.tpl")
  vars = {
    message = "World"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"
  name    = "stenio-vpc"
  cidr    = "10.0.0.0/16"

  azs            = var.availability_zones
  public_subnets = ["10.0.101.0/24", "10.0.201.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Name  = "TFE PoC"
    Owner = "Stenio Ferreira"
    TTL   = "24"
  }
}

resource "aws_instance" "private_ec2" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_size
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.aws_key
  user_data              = data.template_file.init.rendered

  tags = {
    Name  = "TFE PoC ec2-${count.index}"
    Owner = "Stenio Ferreira"
    TTL   = "24"
  }
}

resource "aws_instance" "bastion_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_bastion_sg.id]
  key_name               = var.aws_key
  user_data              = data.template_file.init.rendered
  tags = {
    Name  = "TFE PoC ec2Bastion"
    Owner = "Stenio Ferreira"
    TTL   = "24"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg_PoC"
  description = "SG for TFE Poc - Stenio Ferreira"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
      iterator = port
      for_each = var.ingress_ports
      content {
        from_port   = port.value
        to_port     = port.value
        protocol    = "tcp"
        security_groups = ["${aws_security_group.lb_sg.id}", "${aws_security_group.ec2_bastion_sg.id}"]
      }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_bastion_sg" {
  name        = "ec2_sg_bastionPoC"
  description = "SG for bastion TFE Poc - Stenio Ferreira"
  vpc_id      = module.vpc.vpc_id

 dynamic "ingress" {
      iterator = port
      for_each = var.ingress_ports
      content {
        from_port   = port.value
        to_port     = port.value
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
  }
  /** # Example specifying individually
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_security_group.lb_sg.id}"]
  }
  */
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg_PoC"
  description = "SG for TFE Poc - Stenio Ferreira"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
      iterator = port
      for_each = var.ingress_ports
      content {
        from_port   = port.value
        to_port     = port.value
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "elb" {
  name            = "stenio-ptfe-elb"
  security_groups = [aws_security_group.lb_sg.id]

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
    #ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  }
  listener {
    instance_port     = 2299
    instance_protocol = "tcp"
    lb_port           = 2299
    lb_protocol       = "tcp"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:2299/index.html"
    interval            = 30
  }

  instances = "${aws_instance.private_ec2[*].id}"
  subnets = module.vpc.public_subnets

  tags = {
    Name  = "TFE PoC LB"
    Owner = "Stenio Ferreira"
    TTL   = "24"
  }
}

