#vpc
resource "aws_vpc" "stag-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "stag-vpc"
  }
}
#azs
data "aws_availability_zones" "available" {
  state = "available"

}


#create igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.stag-vpc.id

  tags = {
    Name = "stage-igw"
  }
}

# # public subnet1

resource "aws_subnet" "stag-public1" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.stag-vpc.id
  map_public_ip_on_launch = true
  cidr_block              = element(var.public1_cidr, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)


  tags = {
    Name = "${count.index + 1}stage_public1"
  }
}

#private subnet
resource "aws_subnet" "stag-private1" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.stag-vpc.id
  map_public_ip_on_launch = true
  cidr_block              = element(var.private1_cidr, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)


  tags = {
    Name = "${count.index + 1}stage_private1"
  }
}

#data subnet
resource "aws_subnet" "stag-data1" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.stag-vpc.id
  map_public_ip_on_launch = true
  cidr_block              = element(var.data1_cidr, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)


  tags = {
    Name = "${count.index + 1}stage-data1"
  }
}

#create elastic ip
resource "aws_eip" "eip" {
  vpc = true
}

#create nat-gw
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.stag-public1[0].id

  tags = {
    Name = "nat-gw"
  }
  depends_on = [
    aws_eip.eip
  ]
}

#route table
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.stag-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }



  tags = {
    Name = "route-public"
  }
}




resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.stag-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }



  tags = {
    Name = "route-private"
  }
}





resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.stag-public1[*].id)
  subnet_id      = element(aws_subnet.stag-public1[*].id, count.index)
  route_table_id = aws_route_table.public-route.id
}


resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.stag-public1[*].id)
  subnet_id      = element(aws_subnet.stag-private1[*].id, count.index)
  route_table_id = aws_route_table.private-route.id
}



resource "aws_route_table_association" "data" {
  count          = length(aws_subnet.stag-public1[*].id)
  subnet_id      = element(aws_subnet.stag-data1[*].id, count.index)
  route_table_id = aws_route_table.private-route.id
}

# bastion-sg
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow admin"
  vpc_id      = aws_vpc.stag-vpc.id


  ingress {
    description = "connecting to bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "loadbalancer-sg" {
  name        = "loadbalancer"
  description = "Allow end user"
  vpc_id      = aws_vpc.stag-vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "loadbalancer-sg"
  }
}


resource "aws_security_group" "application-sg" {
  name        = "application"
  description = "Allow ssh"
  vpc_id      = aws_vpc.stag-vpc.id

  ingress {
    description     = "TLS from VPC"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description     = "TLS from VPC"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.loadbalancer-sg.id]
    # ipv6_tags = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "application-sg"
  }
}


# bastion:
resource "aws_instance" "bastion1" {
  ami                    = "ami-06489866022e12a14"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.stag-public1[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.pavan1.id
  tags = {
    Name = "bastion1"
  }
}

# application
resource "aws_instance" "application1" {
  ami                    = "ami-06489866022e12a14"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.stag-public1[1].id
  vpc_security_group_ids = [aws_security_group.application-sg.id]
  # count                  = 1
  key_name  = aws_key_pair.pavan1.id
  user_data = <<-EOF
            #/bin/bash
             yum update -y
             yum install httpd -y
             systemctl start httpd
             systemctl enable httpd
             EOF
  tags = {
    Name = "application1{count.index}"

  }
}
