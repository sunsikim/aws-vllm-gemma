resource "aws_security_group" "vllm" {
  name        = "${var.name_prefix}-sg"
  description = "Allow vLLM server traffic only; all other access via SSM"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vllm_port" {
  security_group_id = aws_security_group.vllm.id
  description       = "vLLM OpenAI-compatible API"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.vllm_port
  to_port           = var.vllm_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.vllm.id
  description       = "Allow all outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
