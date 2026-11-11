output "vpc_id" {
    value=aws_vpc.main.id
}
output "public_subnets_ids" {
    value =  [ for s in aws_subnet.public :s.id]
}
output "private_subnets_ids"{
    value = [for s in aws_subnet.private :  s.id]
}
output "rt-public"{
    value = aws_route_table.public[*].id
}