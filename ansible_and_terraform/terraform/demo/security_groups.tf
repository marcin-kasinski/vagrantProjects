/*

resource "aws_security_group" "allow_ssh_from_main_server" {
  name        = "allow_ssh_from_main_server"
  description = "Allow ssh from main server"

  ingress {
    # Allow ssh from main server
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["46.31.39.119/32"] # add your IP address here
	#cidr_blocks = ["0.0.0.0/0"] # add your IP address here

 
  }

 
}
*/

resource "aws_security_group" "allow_ssh_from_main_server_vpc" {
  name        = "allow_ssh_from_main_server_vpc"
  description = "Allow ssh from main server_vpc"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    # Allow ssh from main server
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["46.31.39.119/32","10.0.0.0/16"] # add your IP address here

 
  }

  tags ={
    Name = "allow_ssh_from_main_server_vpc"
  }
 
 
}




resource "aws_security_group" "allow-outside" {
  vpc_id = "${aws_vpc.main.id}"
  name = "allow-outside"
  description = "security group that allows allow-outside traffic"
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

 tags ={
    Name = "allow-outside"
  }
}




resource "aws_security_group" "allow_icmp" {
  name        = "allow_icmp"
  description = "Allow icmp"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    # Allow ivmp
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["10.0.0.0/16"] # add your IP address here

 
  }

  tags ={
    Name = "allow_icmp"
  }
 
}

