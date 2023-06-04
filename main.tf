# create a vpc 
resource "aws_vpc" "vpc-tf" {
  cidr_block           = var.vpc-cidr
  instance_tenancy     = var.tenancy
  enable_dns_hostnames = var.true
  enable_dns_support   = var.true

  tags = {
    Name = "terraform-vpc"
  }
}

# create internet gateway
resource "aws_internet_gateway" "ig" {
    vpc_id = "${aws_vpc.vpc-tf.id}"
}  

# create a public subnet 
resource "aws_subnet" "public_subnet" {
    vpc_id = "${aws_vpc.vpc-tf.id}"
    cidr_block = "192.168.1.0/24"
    map_public_ip_on_launch = true
}

# create private subnet 
resource "aws_subnet" "private_subnet" {
    vpc_id = "${aws_vpc.vpc-tf.id}"
    cidr_block = "192.168.2.0/24"
    map_public_ip_on_launch = false
}

# create elastic ip for nat gateway 
resource "aws_eip" "nat_eip" {
    vpc = true
    depends_on = [aws_internet_gateway.ig]
}

# create NAT gateway 
resource "aws_nat_gateway" "nat" {
    allocation_id = "${aws_eip.nat_eip.id}"
    subnet_id = "${aws_subnet.private_subnet.id}"
    depends_on = [aws_internet_gateway.ig]
}

# routing table for a private subnet 
resource "aws_route_table" "private" {
    vpc_id = "${aws_vpc.vpc-tf.id}"
}  

# routing table for a public subnet 
resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.vpc-tf.id}"
}

resource "aws_route" "public_internet_gateway" {
    route_table_id         = "${aws_route_table.public.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = "${aws_internet_gateway.ig.id}"
}

resource "aws_route" "private_nat_gateway" {
    route_table_id         = "${aws_route_table.private.id}"
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}

# public route table association 
resource "aws_route_table_association" "public" {
    subnet_id = "${aws_subnet.public_subnet.id}"
    route_table_id = "${aws_route_table.public.id}"
}  

# private route table association 
resource "aws_route_table_association" "private" {
    subnet_id      = "${aws_subnet.private_subnet.id}"
    route_table_id = "${aws_route_table.private.id}"
}

# create a security group and allow ssh 
resource "aws_security_group" "ssh-security-group" {
    name        = "SSH Security Group"
    description = "Enable SSH access on Port 22"
    vpc_id      = aws_vpc.vpc-tf.id
    ingress {
        description      = "SSH Access"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
}
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
}
    tags   = {
        Name = "SSH Security Group"
}
}

# create EC2 instance in a public subnet 
resource "aws_instance" "app_instance" {
    ami  = "ami-006dcf34c09e50022"
    instance_type  = "t2.micro"
    key_name   = "soliman-serevr"
    security_groups = ["${aws_security_group.ssh-security-group.id}"]
    subnet_id = "${aws_subnet.public_subnet.id}"
    associate_public_ip_address = true 
}

# create ec2 instance in a private subnet 
resource "aws_instance" "DB_instance" {
    ami  = "ami-006dcf34c09e50022"
    instance_type  = "t2.micro"
    key_name   = "soliman-serevr"
    security_groups = ["${aws_security_group.ssh-security-group.id}"]
    subnet_id = "${aws_subnet.private_subnet.id}"
    associate_public_ip_address = false
}
