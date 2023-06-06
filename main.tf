# Create a VPC
resource "aws_vpc" "info-tech-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name= "Info-tech-vpc"
  }
}
# create public subnet
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.info-tech-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public-subnet"
  }
}
#create private subnet
resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.info-tech-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private-subnet"
  }
}
#create security group
resource "aws_security_group" "info-tech-sg" {
  name        = "Infor-tech-SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.info-tech-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }


ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "Infor-tech-SG"
  }
}

#create internet gateway
resource "aws_internet_gateway" "info-tech-gw" {
  vpc_id = aws_vpc.info-tech-vpc.id

  tags = {
    Name = "Info-tech-IGW"
  }
}
#Create route table
resource "aws_route_table" "Public_route_table" {
  vpc_id = aws_vpc.info-tech-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.info-tech-gw.id
  }
  tags = {
    Name = "Public-route Table"
  }
} 
#associate route table 
resource "aws_route_table_association" "public-rt-ass" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.Public_route_table.id
}
#create instance for webserver
resource "aws_instance" "web-server" {
  ami           = "ami-0715c1897453cabd1" # us-east-1
  instance_type = "t2.micro"
  key_name      = "key1"
  subnet_id     = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.info-tech-sg.id]
  connection {
    type ="ssh"
    host = self.public_ip
    user =  ec2-user
    private_key = file("./key1.pem")
  }
  tags = {
    Name = "web server"
    }
}
# create eip
resource "aws_eip" "info-tech-aws-eip" {
  instance = aws_instance.web-server.id
  vpc   = true
}
#create instance for db
resource "aws_instance" "db-server" {
  ami           = "ami-0715c1897453cabd1" # us-east-1
  instance_type = "t2.micro"
  key_name      = "key1"
  subnet_id     = aws_subnet.private-subnet.id
  vpc_security_group_ids = [aws_security_group.info-tech-sg.id]
  connection {
    type ="ssh"
    #host = self.public_ip
    user =  ec2-user
    private_key = file("./key1.pem")
  }
  tags = {
    Name = "db server"
    }
}
# create eip
resource "aws_eip" "info-tech-aws-ngw-id" {
  vpc   = true
}
# create nat gateway
resource "aws_nat_gateway" "aws-ngw" {

  subnet_id     = aws_subnet.public-subnet.id
  allocation_id = aws_eip.info-tech-aws-ngw-id.id
  tags = {
    Name = "NAT gateway"
  }
}
#create route table for private subnet
resource "aws_route_table" "private_route_table" {
    vpc_id = aws_vpc.info-tech-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.aws-ngw.id
    }
    tags = {
      Name = "Private route table"
    }
  
}
# route table association
resource "aws_route_table_association" "private-rt-asso" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private_route_table.id
}