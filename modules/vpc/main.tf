

resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    tags = {Name = "${var.environment}-vpc"}
}
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = {Name = "${var.environment}-igw"}
}
resource "aws_subnet" "public" {
    for_each = var.public_subnets
    vpc_id = aws_vpc.main.id
    cidr_block = each.value 
    availability_zone = each.key
    map_public_ip_on_launch = true
    tags = {Name = "${var.environment}-public${each.key}"}
}
resource "aws_subnet" "private" {
    for_each = var.private_subnets
    vpc_id = aws_vpc.main.id
    cidr_block = each.value
    availability_zone = each.key
    tags = {Name = "${var.environment}-private${each.key}"}
}
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
    tags = {Name="${var.environment}-rt-public"}
}
resource "aws_route_table_association" "public" {
    for_each = aws_subnet.public
    subnet_id = each.value.id
    route_table_id = aws_route_table.public.id
}

