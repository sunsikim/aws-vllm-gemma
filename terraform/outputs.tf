output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "security_group_id" {
  value = aws_security_group.vllm.id
}

output "iam_role_arn" {
  value = aws_iam_role.instance.arn
}

output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.instance.name
}

output "instance_id" {
  value = aws_instance.vllm.id
}

output "instance_public_ip" {
  value = aws_instance.vllm.public_ip
}

output "vllm_endpoint" {
  value = "http://${aws_instance.vllm.public_ip}:${var.vllm_port}"
}
