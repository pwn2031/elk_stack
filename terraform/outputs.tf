output "elk_instance_id" {
  description = "ID of the ELK EC2 instance"
  value       = aws_instance.elk_server.id
}

output "elk_public_ip" {
  description = "Public IP of the ELK EC2 instance"
  value       = aws_instance.elk_server.public_ip
}

output "elk_public_dns" {
  description = "Public DNS of the ELK EC2 instance"
  value       = aws_instance.elk_server.public_dns
}

output "kibana_url" {
  description = "Kibana URL (HTTP) on the ELK instance"
  value       = "http://${aws_instance.elk_server.public_ip}:5601"
}

