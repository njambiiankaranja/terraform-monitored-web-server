output "website_url" {
  description = "Public address of the web server"
  value       = "http://${aws_instance.web.public_ip}"
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "ssm_connect_command" {
  description = "Command to open a shell on the instance without SSH"
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}"
}