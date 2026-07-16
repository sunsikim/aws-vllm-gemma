resource "aws_instance" "vllm" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.vllm.id]
  iam_instance_profile   = aws_iam_instance_profile.instance.name

  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    model_bucket_name   = var.model_bucket_name
    model_bucket_prefix = var.model_bucket_prefix
    docker_compose_yaml = file("${path.module}/docker-compose.yml")
  })

  tags = {
    Name = "${var.name_prefix}-instance"
  }
}
