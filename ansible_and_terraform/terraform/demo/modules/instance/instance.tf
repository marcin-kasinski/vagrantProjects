
resource "aws_instance" "this" {
  ami           = "${var.AMI}"
  instance_type = "t2.micro"
  key_name      = "${var.KEY_NAME}"
  
  # the VPC subnet
  subnet_id = "${var.SUBNET_ID}"
  
  tags ={
        Name = "${var.NAME}",
        Size = "small one"
    }
    
  # the security group
  #vpc_security_group_ids = ["${aws_security_group.allow_ssh_from_main_server_vpc.id}","${aws_security_group.allow_icmp.id}","${aws_security_group.allow-outside.id}"]
  #vpc_security_group_ids = ["allow_ssh_from_main_server_vpc","allow-outside","allow_icmp"]
  
  vpc_security_group_ids = var.VPC_SECURITY_GROUP_IDS
  
  #depends_on="${var.DEPENDS_ON}"
  private_ip="${var.PRIVATE_IP}"  
  
  #security_groups = [
  #  "default",
  #  "allow_ssh_from_main_server"
  #]

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sed -i -e 's/\r//g' /tmp/script.sh",
      "sudo /tmp/script.sh ${aws_instance.this.public_ip}",
      "echo 'public_ip ${aws_instance.this.public_ip}'",

    ]
  }
  connection {
    host        			= "${var.PRIVATE_IP}"
    user        			= "${var.INSTANCE_USERNAME}"
    private_key 			= "${file("${var.PATH_TO_PRIVATE_KEY}")}"
    bastion_host			= "${var.BASTION_HOST}"
    bastion_private_key		= "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

}



#output "ip_private" {
#  value = "${module.private_ip}"
#}



output "private_ip" {
  value       = aws_instance.this.private_ip
  description = "The private IP address of the server instance."
}

