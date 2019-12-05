output "lb_dns" {
  value = "${aws_elb.elb.dns_name}"
}

output "bastion_ip" {
  value = "${aws_instance.bastion_ec2.public_ip}"
}
output "private_ips" {
  value = "${aws_instance.private_ec2.*.private_ip}"
}