output "dharan_nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.dharan_nlb.dns_name
}

output "dharan_instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.dharan_nginx_instance.public_ip
}
