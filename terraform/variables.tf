variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-northeast-2"
}

variable "name_prefix" {
  description = "Prefix applied to resource names and tags"
  type        = string
  default     = "vllm-gemma"
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet the instance will run in"
  type        = string
  default     = "10.0.0.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
  default     = "ap-northeast-2a"
}

variable "vllm_port" {
  description = "Port the vLLM OpenAI-compatible server listens on"
  type        = number
  default     = 8000
}

variable "model_bucket_name" {
  description = "S3 bucket containing model artifacts to be mounted via mount-s3"
  type        = string
  default     = "blank-llm-batch"
}

variable "model_bucket_prefix" {
  description = "Prefix within model_bucket_name that the instance is allowed to read"
  type        = string
  default     = "models"
}

variable "ami_id" {
  description = "Pinned AMI ID (Deep Learning Base AMI with Single CUDA, Amazon Linux 2023)"
  type        = string
  default     = "ami-0f68bfb7fe05d3c2c"
}

variable "instance_type" {
  description = "EC2 instance type to run vLLM on"
  type        = string
  default     = "g7e.2xlarge"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 30
}
