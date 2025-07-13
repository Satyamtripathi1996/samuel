data "aws_iam_policy_document" "s3_bucket_policy" {
    for_each = { for bucket in var.buckets_list : bucket.bucket_name=> bucket}
  statement {
    sid = "requestwithoutssl"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*" 
    ]
    resources = [
        "arn:aws:s3:::${each.value.bucket_name}",
        "arn:aws:s3:::${each.value.bucket_name}/*"
          ]

    condition {
        
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
}
    statement {
        sid = "userpermissions"
        effect = "Allow"
        principals {
            type        = "AWS"
            identifiers = [
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            ]
        }
        actions = [
            "s3:*",
        ]
        resources = [
            "arn:aws:s3:::${each.value.bucket_name}",
            "arn:aws:s3:::${each.value.bucket_name}/*"
        ]
    }
}