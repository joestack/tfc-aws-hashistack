//--------------------------------------------------------------------
// IAM and Policy Resources

## Vault Server IAM Config
resource "aws_iam_instance_profile" "hc-stack-server" {
  name = "${var.name}-hc-stack-server-instance-profile"
  role = aws_iam_role.hc-stack-server.name
}

resource "aws_iam_role" "hc-stack-server" {
  name               = "${var.name}-hc-stack-server-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "hc-stack-server" {
  name   = "${var.name}-hc-stack-server-role-policy"
  role   = aws_iam_role.hc-stack-server.id
  policy = data.aws_iam_policy_document.hc-stack-server.json
}

# Vault Client IAM Config
resource "aws_iam_instance_profile" "hc-stack-client" {
  name = "${var.name}-hc-stack-client-instance-profile"
  role = aws_iam_role.hc-stack-client.name
}

resource "aws_iam_role" "hc-stack-client" {
  name               = "${var.name}-hc-stack-client-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "hc-stack-client" {
  name   = "${var.name}-hc-stack-client-role-policy"
  role   = aws_iam_role.hc-stack-client.id
  policy = data.aws_iam_policy_document.hc-stack-client.json
}

//--------------------------------------------------------------------
// Data Sources

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "hc-stack-server" {
  statement {
    sid    = "RaftSingle"
    effect = "Allow"

    actions = ["ec2:DescribeInstances"]

    resources = ["*"]
  }

  statement {
    sid    = "VaultAWSAuthMethod"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "iam:GetInstanceProfile",
      "iam:GetUser",
      "iam:GetRole",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "VaultKMSUnseal"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "hc-stack-client" {
  statement {
    sid    = "RaftSingle"
    effect = "Allow"

    actions = ["ec2:DescribeInstances"]

    resources = ["*"]
  }
}