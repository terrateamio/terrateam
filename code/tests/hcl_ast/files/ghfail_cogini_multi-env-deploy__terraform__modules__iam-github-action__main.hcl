# Create IAM role that allows a GitHub Action to call AWS
#
# https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
# https://scalesec.com/blog/identity-federation-for-github-actions-on-aws/
# https://stackoverflow.com/questions/69243571/how-can-i-connect-github-actions-with-aws-deployments-without-using-a-secret-key
# https://github.com/aws-actions/aws-codebuild-run-build
# https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/

# Example:
# terraform {
#   source = "${dirname(find_in_parent_folders())}/modules//iam-github-action"
# }
# dependency "cloudfront" {
#   config_path = "../cloudfront-app-assets"
# }
# dependency "codedeploy-app" {
#   config_path = "../codedeploy-app"
# }
# dependency "codedeploy-deployment" {
#   config_path = "../codedeploy-deployment-app"
# }
# dependency "ecr-app" {
#   config_path = "../ecr-app"
# }
# dependency "ecr-otel" {
#   config_path = "../ecr-otel"
# }
# dependency "ecs-cluster" {
#   config_path = "../ecs-cluster"
# }
# dependency "ecs-service-app" {
#   config_path = "../ecs-service-app"
# }
# dependency "ecs-service-worker" {
#   config_path = "../ecs-service-worker"
# }
# dependency "iam-ecs-task-execution" {
#   config_path = "../iam-ecs-task-execution"
# }
# dependency "iam-ecs-task-role" {
#   config_path = "../iam-ecs-task-role-app"
# }
# dependency "kms" {
#   config_path = "../kms"
# }
# dependency "s3" {
#   config_path = "../s3-app"
# }
# include "root" {
#   path = find_in_parent_folders()
# }
#
# inputs = {
#   comp = "app"
#
#   sub = "repo:cogini/foo:*"
#
#   s3_buckets = [
#     dependency.s3.outputs.buckets["assets"].id
#   ]
#
#   enable_cloudfront = true
#
#   ecr_arns = [
#     dependency.ecr-app.outputs.arn,
#     dependency.ecr-otel.outputs.arn
#   ]
#
#   ecs = [
#     {
#       service_arn                      = dependency.ecs-service-app.outputs.id
#       task_role_arn                    = dependency.iam-ecs-task-role.outputs.arn
#       execution_role_arn               = dependency.iam-ecs-task-execution.outputs.arn
#       codedeploy_application_name      = dependency.codedeploy-app.outputs.app_name
#       codedeploy_deployment_group_name = dependency.codedeploy-deployment.outputs.deployment_group_name
#     },
#     {
#       service_arn                      = dependency.ecs-service-worker.outputs.id
#       task_role_arn                    = dependency.iam-ecs-task-role.outputs.arn
#       execution_role_arn               = dependency.iam-ecs-task-execution.outputs.arn
#     }
#   ]
#
#   ec2 = [
#       {
#         codedeploy_application_name      = dependency.codedeploy-app.outputs.app_name
#         codedeploy_deployment_group_name = dependency.codedeploy-deployment.outputs.deployment_group_name
#       }
#     ]
#
#   kms_key_id = dependency.kms.outputs.key_arn
# }

data "aws_caller_identity" "current" {}

locals {
  aws_account_id    = var.aws_account_id == "" ? data.aws_caller_identity.current.account_id : var.aws_account_id
  name              = var.name == "" ? "${var.org}-${var.app_name}-${var.env}-${var.comp}" : var.name
  enable_s3         = length(var.s3_buckets) > 0
  enable_cloudfront = var.enable_cloudfront
  enable_ecr        = length(var.ecr_arns) > 0
  enable_ecs        = length(var.ecs) > 0
  enable_codebuild  = var.codebuild_project_name != ""
  kms_key_id        = var.kms_key_id
  subs              = var.subs == null ? [var.sub] : var.subs

  ecs_task_roles      = [for r in var.ecs : r.task_role_arn]
  ecs_execution_roles = [for r in var.ecs : r.execution_role_arn]
  ecs_service_arns    = [for r in var.ecs : r.service_arn]
  ecs_codedeploy_arns = flatten([for r in var.ecs :
    try(r.codedeploy_application_name, null) != null ?
    [
      "arn:${var.aws_partition}:codedeploy:${var.aws_region}:${local.aws_account_id}:deploymentgroup:${r.codedeploy_application_name}/${r.codedeploy_deployment_group_name}",
      "arn:${var.aws_partition}:codedeploy:${var.aws_region}:${local.aws_account_id}:deploymentconfig:*",
      "arn:${var.aws_partition}:codedeploy:${var.aws_region}:${local.aws_account_id}:application:${r.codedeploy_application_name}"
    ] : []
  ])

  ec2_codedeploy_arns = flatten([for r in var.ec2 :
    try(r.codedeploy_application_name, null) != null ?
    [
      "arn:${var.aws_partition}:codedeploy:${var.aws_region}:${local.aws_account_id}:deploymentgroup:${r.codedeploy_application_name}/${r.codedeploy_deployment_group_name}",
      "arn:${var.aws_partition}:codedeploy:${var.aws_region}:${local.aws_account_id}:deploymentconfig:*",
      "arn:${var.aws_partition}:codedeploy:${var.aws_region}:${local.aws_account_id}:application:${r.codedeploy_application_name}"
    ] : []
  ])

  enable_codedeploy = length(local.ec2_codedeploy_arns) > 0
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:${var.aws_partition}:iam::${local.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Use subject (sub) condition key for iam
    # https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#available-keys-for-iam
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.subs
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.name}-github-action"
  description        = "Allow GitHub Action to call AWS services"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# Give access to S3 buckets
data "aws_iam_policy_document" "s3" {
  count = local.enable_s3 ? 1 : 0

  # Allow actions on buckets
  dynamic "statement" {
    for_each = var.s3_buckets
    content {
      actions = [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:CreateMultipartUpload",
      ]
      resources = ["arn:${var.aws_partition}:s3:::${statement.value}"]
    }
  }

  # Allow actions on bucket contents
  dynamic "statement" {
    for_each = var.s3_buckets
    content {
      actions = [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:CreateMultipartUpload",
      ]
      resources = ["arn:${var.aws_partition}:s3:::${statement.value}/*"]
    }
  }

  statement {
    actions = [
      "s3:ListObjects"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3" {
  count = local.enable_s3 ? 1 : 0

  name_prefix = "${local.name}-github-action-s3-"
  description = "Allow access to S3 buckets"
  policy      = data.aws_iam_policy_document.s3[0].json
}

resource "aws_iam_role_policy_attachment" "github-action-s3" {
  count = local.enable_s3 ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3[0].arn
}


# Add permissions to create CloudFront invalidation
data "aws_iam_policy_document" "cloudfront" {
  count = local.enable_cloudfront ? 1 : 0

  statement {
    actions = [
      "acm:ListCertificates",
      "cloudfront:GetDistribution",
      "cloudfront:GetStreamingDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudfront:ListCloudFrontOriginAccessIdentities",
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:ListInvalidations",
      "elasticloadbalancing:DescribeLoadBalancers",
      "iam:ListServerCertificates",
      "sns:ListSubscriptionsByTopic",
      "sns:ListTopics",
      "waf:GetWebACL",
      "waf:ListWebACLs",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudfront" {
  count = local.enable_cloudfront ? 1 : 0

  name_prefix = "${local.name}-github-action-cloudfront"
  description = "Allow GitHub Action to access CloudFront"
  policy      = data.aws_iam_policy_document.cloudfront[0].json
}

resource "aws_iam_role_policy_attachment" "github-action-cloudfront" {
  count = local.enable_cloudfront ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.cloudfront[0].arn
}


# Add permissions to access ECR
data "aws_iam_policy_document" "ecr" {
  count = local.enable_ecr ? 1 : 0

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = var.ecr_arns
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr" {
  count = local.enable_ecr ? 1 : 0

  name_prefix = "${local.name}-github-action-ecr-"
  description = "Allow GitHub Action to access ECR"
  policy      = data.aws_iam_policy_document.ecr[0].json
}

resource "aws_iam_role_policy_attachment" "github-action-ecr" {
  count = local.enable_ecr ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ecr[0].arn
}


# Run CodeBuild and get resulting log messages
# https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up.html
# https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html
data "aws_iam_policy_document" "codebuild" {
  count = local.enable_codebuild ? 1 : 0

  statement {
    actions = [
      # Required to start running builds
      "codebuild:StartBuild",
      # Required to get information about builds
      "codebuild:BatchGetBuilds"
    ]
    resources = ["arn:${var.aws_partition}:codebuild:${var.aws_region}:${local.aws_account_id}:project/${var.codebuild_project_name}"]
  }

  statement {
    actions = [
      "logs:GetLogEvents",
    ]
    resources = ["arn:${var.aws_partition}:logs:${var.aws_region}:${local.aws_account_id}:log-group:/aws/codebuild/${var.codebuild_project_name}:*"]
  }
}

resource "aws_iam_policy" "codebuild" {
  count = local.enable_codebuild ? 1 : 0

  name_prefix = "${local.name}-github-action-codebuild-"
  description = "Allow GitHub Action to run CodeBuild"
  policy      = data.aws_iam_policy_document.codebuild[0].json
}

resource "aws_iam_role_policy_attachment" "github-action" {
  count = local.enable_codebuild ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.codebuild[0].arn
}


# Deploy via ECS
# https://github.com/aws-actions/amazon-ecs-deploy-task-definition
data "aws_iam_policy_document" "ecs" {
  count = local.enable_ecs ? 1 : 0

  statement {
    actions = [
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = concat(local.ecs_task_roles, local.ecs_execution_roles)
  }

  statement {
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]
    resources = local.ecs_service_arns
  }

  # When using CodeDeploy, "ecs:UpdateService" is not needed
  # dynamic "statement" {
  #   for_each = local.enable_codedeploy ? [] : tolist([1])
  #   content {
  #     actions   = [
  #       "ecs:UpdateService",
  #       "ecs:DescribeServices"
  #     ]
  #     resources = [
  #       "arn:${var.aws_partition}:ecs:${var.aws_region}:${local.aws_account_id}:service/${local.ecs.cluster_name}/${local.ecs.service_name}"
  #     ]
  #   }
  # }
  #
  # dynamic "statement" {
  #   for_each = local.enable_codedeploy ? tolist([1]) : []
  #   content {
  #     actions   = [
  #       "ecs:DescribeServices"
  #     ]
  #     resources = [
  #       "arn:${var.aws_partition}:ecs:${var.aws_region}:${local.aws_account_id}:service/${local.ecs.cluster_name}/${local.ecs.service_name}"
  #     ]
  #   }
  # }

  dynamic "statement" {
    for_each = local.enable_codedeploy ? tolist([1]) : []
    content {
      actions = [
        "codedeploy:GetDeploymentGroup",
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
      ]
      resources = local.ecs_codedeploy_arns
    }
  }
}

resource "aws_iam_policy" "ecs" {
  count = local.enable_ecs ? 1 : 0

  name_prefix = "${local.name}-github-action-ecs-"
  description = "Deploy to ECS"
  policy      = data.aws_iam_policy_document.ecs[0].json
}

resource "aws_iam_role_policy_attachment" "ecs" {
  count = local.enable_ecs ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ecs[0].arn
}


# Create CodeDeploy deployment
data "aws_iam_policy_document" "codedeploy-app-deploy" {
  count = local.enable_codedeploy ? 1 : 0

  dynamic "statement" {
    for_each = local.enable_codedeploy ? tolist([1]) : []
    content {
      actions = [
        "codedeploy:GetDeploymentGroup",
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:GetApplicationRevision",
        "codedeploy:RegisterApplicationRevision"
      ]
      resources = local.ec2_codedeploy_arns
    }
  }

  # Allow writing revision to deploy bucket
  # statement {
  #   actions = ["s3:ListBucket"]
  #   resources = ["${local.codedeploy_bucket_arn}/*"]
  # }
  # statement {
  #   actions = ["s3:PutObject*"]
  #   resources = [local.codedeploy_bucket_arn]
  # }
  # statement {
  #   actions   = ["s3:ListAllMyBuckets"]
  #   resources = ["*"]
  # }
}

resource "aws_iam_policy" "codedeploy-app-deploy" {
  count = local.enable_codedeploy ? 1 : 0

  name        = "${local.name}-codedeploy-app-deploy"
  description = "Create CodeDeploy revision for app and deploy to app-deploy S3 bucket"
  policy      = data.aws_iam_policy_document.codedeploy-app-deploy[0].json
}

resource "aws_iam_role_policy_attachment" "codedeploy-app-deploy" {
  count = local.enable_codedeploy ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.codedeploy-app-deploy[0].arn
}

# Allow access to S3 bucket encrypted with CMK
# resource "aws_kms_grant" "github-action" {
#   count             = var.kms_key_id != null ? 1 : 0
#   name              = "${var.name}-github-action"
#   key_id            = var.kms_key_id
#   grantee_principal = aws_iam_role.this.arn
#   operations        = ["Encrypt", "Decrypt", "GenerateDataKey", "DescribeKey"]
# }

# KMS
# https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
# https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
# https://repost.aws/knowledge-center/s3-access-denied-error-kms
data "aws_iam_policy_document" "kms" {
  count = local.kms_key_id != null ? 1 : 0

  statement {
    sid = "AllowKeyUsage"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [var.kms_key_id]

    dynamic "condition" {
      for_each = length(var.kms_key_aliases) > 0 ? tolist([1]) : []
      content {
        test     = "ForAnyValue:StringEquals"
        variable = "kms:ResourceAliases"
        values   = var.kms_key_aliases
      }
    }
  }
}

resource "aws_iam_policy" "kms" {
  count = local.kms_key_id != null ? 1 : 0

  name_prefix = "${local.name}-kms-"
  description = "Enable access to KMS"
  policy      = data.aws_iam_policy_document.kms[0].json
}

resource "aws_iam_role_policy_attachment" "kms" {
  count = local.kms_key_id != null ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.kms[0].arn
}
