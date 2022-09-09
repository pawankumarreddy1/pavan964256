output "zones" {
  value = data.aws_availability_zones.available.names
}

output "vpcname" {
  value = aws_vpc.stag-vpc.id
}

output "countofaz" {
  value = length(data.aws_availability_zones.available.names)
}

output "bastion" {
  value = (aws_instance.bastion1.id)
}

output "appplication1" {
  value = (aws_instance.application1.id)
}