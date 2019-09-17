resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
}

resource "aws_instance" "example" {
  ami           = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.mykey.key_name}"
  tags ={
        Name = "example instance",
        Size = "small one"
    }
    
  security_groups = [
    "default",
    "allow_ssh_from_main_server"
  ]


  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sed -i -e 's/\r//g' /tmp/script.sh",
      "sudo /tmp/script.sh ${aws_instance.example.public_ip}",
      "echo 'public_ip ${aws_instance.example.public_ip}'",

    ]
  }
  connection {
    host        = "${self.public_ip}"
    user        = "${var.INSTANCE_USERNAME}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

}



output "ip" {
  value = "${aws_instance.example.public_ip}"
}
