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
  template = "${file("vault_bootstrap_demo.sh.tpl")}"
  vars = {
    vault_zip_url = var.vault_zip_url
    vault_license = var.vault_license
  }
}

resource "aws_instance" "ubuntu" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "${var.aws_instance_type}"
  availability_zone = "${var.aws_az}"

  key_name    = var.aws_key
  user_data = "${data.template_file.init.rendered}"
  vpc_security_group_ids = ["${aws_security_group.ec2_sg.id}"]
  tags = {
    Owner = "${var.owner}"
    TTL = "${var.ttl}"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg_PoC"
  description = "SG for Vault Poc - Stenio Ferreira"
  ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
        from_port   = 8200
        to_port     = 8200
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
  }

      ingress {
        from_port   = 8201
        to_port     = 8201
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

####
# Google

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "8200", "8201"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_network" "default" {
  name = "test-network"
}

resource "google_compute_instance" "demo" {
    name = "stenio-vault-demo"
  machine_type = "${var.gcp_machine_type}"
  zone         = "${var.gcp_zone}"

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    network = google_compute_network.default.name

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = "${data.template_file.init.rendered}"
 
  labels = {
    owner = "${var.owner}"
    ttl = "${var.ttl}"
  }
}