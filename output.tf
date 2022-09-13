output "zones" {
  value = data.aws_availability_zones.available.names
}

output "vpcname" {
  value = aws_vpc.stag-vpc.id
}

output "countofaz" {
  value = length(data.aws_availability_zones.available.names)
}
output "cicdip" {
  value = aws_instance.jenkins1.public_ip

}

output "apache2ip" {
  value = aws_instance.apache2.public_ip
  
}

output "apache2pubdns" {
  value = aws_instance.apache2.public_dns
  
}

output "cicdpubdns" {
  value = aws_instance.jenkins1.public_dns
  
}