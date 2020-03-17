output "aws_external_ip" {
  value = "${aws_instance.ubuntu.public_ip}"
}

output "gcp_external_ip"{
  value = "${google_compute_instance.demo.network_interface.0.access_config.0.nat_ip}"
}

output "rds_url"{
  value = "${aws_db_instance.default.endpoint}"
}

output "modoule_ouput"{
  value = "${module.outputhelloworld.output_message}"
}