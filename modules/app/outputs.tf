output "security_group_id" {
  value = aws_security_group.app.id
}

output "instance_id" {
  value = aws_instance.app.id
}

output "url" {
  value = "http://${aws_instance.app.public_ip}"
}