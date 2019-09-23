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



module "instancedb" {
  source              = "./modules/instance"
  
  NAME              = "db"
  SUBNET_ID         = "${aws_subnet.main-private-1.id}"
  PRIVATE_IP        = "10.0.4.10"
  KEY_NAME          = "${aws_key_pair.mykey.key_name}"
  
  PATH_TO_PRIVATE_KEY= "/vagrant/terraform/mykey"
    
 #DEPENDS_ON = "${list("${aws_security_group.allow_ssh_from_main_server_vpc.id}","${aws_security_group.allow_icmp.id}","${aws_security_group.allow-outside.id}")}"
  
  AMI				= "ami-07d0cf3af28718ef8"
  
  BASTION_HOST		= "${aws_instance.web.public_ip}"
  #VPC_SECURITY_GROUP_IDS = ["sg-0184e989d858045c5", "sg-01ab01e66ec860f82","sg-094e10a91db198182"]
  VPC_SECURITY_GROUP_IDS = ["${aws_security_group.allow_ssh_from_main_server_vpc.id}", "${aws_security_group.allow_icmp.id}","${aws_security_group.allow-outside.id}"]
}


