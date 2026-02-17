output "public_ip" {
  description = "EC2 Elastic IP (고정)"
  value       = aws_eip.n8n_poc.public_ip
}

output "ssh_command" {
  description = "SSH 접속 명령어"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.n8n_poc.public_ip}"
}

output "n8n_url" {
  description = "n8n UI 접속 URL"
  value       = "http://${aws_eip.n8n_poc.public_ip}:5678"
}

output "instance_id" {
  description = "EC2 인스턴스 ID"
  value       = aws_instance.n8n_poc.id
}
