resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
}

resource "aws_instance" "web" {
  ami           = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.mykey.key_name}"
  
  # the VPC subnet
  subnet_id = "${aws_subnet.main-public-1.id}"
  
  tags ={
        Name = "web",
        Size = "small one"
    }
    
    
  private_ip="10.0.1.10"  
  # the security group
  vpc_security_group_ids = ["${aws_security_group.allow_ssh_from_main_server_vpc.id}","${aws_security_group.allow_icmp.id}","${aws_security_group.allow-outside.id}"]
  
  # user data
  #user_data = "${data.template_cloudinit_config.cloudinit-example.rendered}"
  
  
/*
  security_groups = [
    "default",
    "allow_ssh_from_main_server"
  ]
*/

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sed -i -e 's/\r//g' /tmp/script.sh",
      "sudo /tmp/script.sh ${aws_instance.web.public_ip}",
      "echo 'public_ip ${aws_instance.web.public_ip}'",

    ]
  }
  connection {
    host        = "${self.public_ip}"
    user        = "${var.INSTANCE_USERNAME}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

}



output "ip_public" {
  value = "${aws_instance.web.public_ip}"
}
output "ip_private" {
  value = "${aws_instance.web.private_ip}"
}

output "connection" {
  value = "ssh -i /vagrant/terraform/mykey ubuntu@${aws_instance.web.public_ip}"
}
