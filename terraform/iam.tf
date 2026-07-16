data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.name_prefix}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "model_bucket_read" {
  statement {
    sid       = "ListModelPrefix"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.model_bucket_name}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.model_bucket_prefix}/*"]
    }
  }

  statement {
    sid       = "GetModelObjects"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.model_bucket_name}/${var.model_bucket_prefix}/*"]
  }
}

resource "aws_iam_role_policy" "model_bucket_read" {
  name   = "${var.name_prefix}-model-bucket-read"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.model_bucket_read.json
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.instance.name
}
