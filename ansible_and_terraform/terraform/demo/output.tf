
output "web_public_ip" {
  value = "${aws_instance.web.public_ip}"
}
output "web_private_ip" {
  value = "${aws_instance.web.private_ip}"
}

output "web_instance_connection" {
  value = "ssh -i /vagrant/terraform/mykey ubuntu@${aws_instance.web.public_ip}"
}

output "db_private_ip" {
  value = "${module.instancedb.private_ip}"
}


output "selected_security_group" {
  value = "id=${data.aws_security_group.selected_allow_ssh_from_main_server_vpc.id}"
}


