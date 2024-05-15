# ---------------------------------------------------------------------------------------------------------------------
# ¦ VERSIONS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ OPTIONAL ENCRYPTION
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_kms_key" "kms_cmk" {
  description             = var.cmk_settings.description
  enable_key_rotation     = true
  deletion_window_in_days = var.cmk_settings.deletion_window_in_days
  policy                  = data.aws_iam_policy_document.kms_cmk_policy.json
  tags                    = var.resource_tags
}

data "aws_iam_policy_document" "kms_cmk_policy" {
  source_policy_documents   = var.cmk_settings.policy_consumers
  override_policy_documents = concat(
    var.cmk_settings.policy_read_override, 
    var.cmk_settings.policy_management_override, 
  )

  statement {
    sid    = "ReadPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:Describe*",
      "kms:List*",
      "kms:Get*",
    ]
    resources = ["*"]
  }
  
  statement {
    sid    = "ManagementPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_alias" "kms_cmk_alias" {
  count        = var.cmk_settings.alias != null ? 1 : 0
  name         = "alias/${var.cmk_settings.alias}"
  target_key_id = aws_kms_key.kms_cmk.key_id
}
