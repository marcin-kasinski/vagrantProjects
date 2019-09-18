
resource "aws_instance" "db" {
  ami           = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.mykey.key_name}"
  
  # the VPC subnet
  subnet_id = "${aws_subnet.main-private-1.id}"
  
  tags ={
        Name = "dbinstance",
        Size = "small one"
    }
    
  # the security group
  #vpc_security_group_ids = ["${aws_security_group.allow-ssh.id}"]
  vpc_security_group_ids = ["${aws_security_group.allow_ssh_from_main_server_vpc.id}","${aws_security_group.allow-outside.id}"]
  
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
      "sudo /tmp/script.sh ${aws_instance.db.public_ip}",
      "echo 'public_ip ${aws_instance.db.public_ip}'",

    ]
  }
  connection {
    host        			= "${self.private_ip}"
    user        			= "${var.INSTANCE_USERNAME}"
    private_key 			= "${file("${var.PATH_TO_PRIVATE_KEY}")}"
    bastion_host			= "${aws_instance.web.public_ip}"
    bastion_private_key		= "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

}



output "ip_db_private" {
  value = "${aws_instance.db.private_ip}"
}
