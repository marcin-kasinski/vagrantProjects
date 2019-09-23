/*
resource "aws_route53_zone" "mkdomain" {
   name = "mkdomain"
    vpc {
      vpc_id = "${aws_vpc.main.id}"
  }
}

resource "aws_route53_record" "web-record" {
   zone_id = "${aws_route53_zone.mkdomain.zone_id}"
   name = "web.mkdomain"
   type = "A"
   ttl = "300"
   records = ["10.0.1.10"]
}
resource "aws_route53_record" "db-record" {
   zone_id = "${aws_route53_zone.mkdomain.zone_id}"
   name = "db.mkdomain"
   type = "A"
   ttl = "300"
   records = ["10.0.4.10"]
}

output "ns-servers" {
   value = "${aws_route53_zone.mkdomain.name_servers}"
}


*/