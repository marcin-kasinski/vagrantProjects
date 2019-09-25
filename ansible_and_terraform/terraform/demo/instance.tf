resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
}

/*
resource "aws_instance" "web" {
  ami           = "${var.AMI_ID}"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.mykey.key_name}"
  
  # the VPC subnet
  subnet_id = "${aws_subnet.main-public-1.id}"
  
  tags ={
        Name = "web",
        Size = "small one"
    }
    
  
  
  volume_tags = var.VOLUME_TAGS
    
  private_ip="10.0.1.10"  
  # the security group
  vpc_security_group_ids = ["${aws_security_group.allow_ssh_from_main_server_vpc.id}","${aws_security_group.allow_icmp.id}","${aws_security_group.allow-outside.id}"]
  
  # user data
  #user_data = "${data.template_cloudinit_config.cloudinit-example.rendered}"
  

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



*/


variable "web1_volume_tags" { 

	type = "map"
default = {
    Name    = "web1 volume" 
    "Y" = "Y"
  }
	
}

variable "web2_volume_tags" { 

	type = "map"
default = {
    Name    = "web2 volume" 
    "Y" = "Y"
  }
	
}


module "web1" {
  source              = "./modules/instance"
  
  NAME              = "web1"
  SUBNET_ID         = "${aws_subnet.main-public-1.id}"
  PRIVATE_IP        = "10.0.1.10"
  KEY_NAME          = "${aws_key_pair.mykey.key_name}"
  
  PATH_TO_PRIVATE_KEY= "/vagrant/terraform/mykey"
    
 #DEPENDS_ON = "${list("${aws_security_group.allow_ssh_from_main_server_vpc.id}","${aws_security_group.allow_icmp.id}","${aws_security_group.allow-outside.id}")}"
  
  AMI				= "${var.AMI_ID}"
  
  #BASTION_HOST		= "${aws_instance.web.public_ip}"
  #VPC_SECURITY_GROUP_IDS = ["sg-0184e989d858045c5", "sg-01ab01e66ec860f82","sg-094e10a91db198182"]
  VPC_SECURITY_GROUP_IDS = ["${aws_security_group.allow_ssh_from_main_server_vpc.id}", "${aws_security_group.allow_icmp.id}","${aws_security_group.allow-outside.id}"]
  
  VOLUME_TAGS= "${var.web1_volume_tags}"
  
  
}


module "web2" {
  source              = "./modules/instance"
  
  NAME              = "web2"
  SUBNET_ID         = "${aws_subnet.main-public-1.id}"
  PRIVATE_IP        = "10.0.1.11"
  KEY_NAME          = "${aws_key_pair.mykey.key_name}"
  
  PATH_TO_PRIVATE_KEY= "/vagrant/terraform/mykey"
    
 #DEPENDS_ON = "${list("${aws_security_group.allow_ssh_from_main_server_vpc.id}","${aws_security_group.allow_icmp.id}","${aws_security_group.allow-outside.id}")}"
  
  AMI				= "${var.AMI_ID}"
  
  #BASTION_HOST		= "${aws_instance.web.public_ip}"
  #VPC_SECURITY_GROUP_IDS = ["sg-0184e989d858045c5", "sg-01ab01e66ec860f82","sg-094e10a91db198182"]
  VPC_SECURITY_GROUP_IDS = ["${aws_security_group.allow_ssh_from_main_server_vpc.id}", "${aws_security_group.allow_icmp.id}","${aws_security_group.allow-outside.id}"]
  
  VOLUME_TAGS= "${var.web2_volume_tags}"
  
  
}
