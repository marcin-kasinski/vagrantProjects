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
    #cidr_blocks = ["194.93.124.26/32"] # add your IP address here

 
  }

 
}

