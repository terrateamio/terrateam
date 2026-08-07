# Create IAM role that allows a GitHub Action to call AWS
#
# https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
# https://scalesec.com/blog/identity-federation-for-github-actions-on-aws/
# https://stackoverflow.com/questions/69243571/how-can-i-connect-github-actions-with-aws-deployments-without-using-a-secret-key
# https://github.com/aws-actions/aws-codebuild-run-build
# https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/

# Example config:
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
  role_name         = var.role_name == "" ? "${local.name}-github-action" : var.role_name
  policy_name       = var.policy_name == "" ? "${local.name}-github-action" : var.policy_name
  enable_s3         = length(var.s3_buckets) > 0
  enable_cloudfront = var.enable_cloudfront
  enable_ecr        = length(var.ecr_arns) > 0
  enable_ecs        = length(var.ecs) > 0
  enable_codebuild  = var.codebuild_project_name != ""
  kms_key_arn       = var.kms_key_id
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

data "aws_iam_policy_document" "this" {
  # Give access to S3 buckets
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

  # This seems excessive
  dynamic "statement" {
    for_each = local.enable_s3 ? tolist([1]) : []
    content {
      actions = [
        "s3:ListObjects"
      ]
      resources = ["*"]
    }
  }

  # Allow creating CloudFront invalidation
  dynamic "statement" {
    for_each = local.enable_cloudfront ? tolist([1]) : []
      content {
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

  # Access ECR
  dynamic "statement" {
    for_each = local.enable_ecr ? tolist([1]) : []
    content {
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
  }

  dynamic "statement" {
    for_each = local.enable_ecr ? tolist([1]) : []
    content {
      actions = [
        "ecr:GetAuthorizationToken",
      ]
      resources = ["*"]
    }
  }

  # Run CodeBuild and get resulting log messages
  # https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up.html
  # https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html
  dynamic "statement" {
    for_each = local.enable_codebuild ? tolist([1]) : []
    content {
      actions = [
        # Required to start running builds
        "codebuild:StartBuild",
        # Required to get information about builds
        "codebuild:BatchGetBuilds"
      ]
      resources = ["arn:${var.aws_partition}:codebuild:${var.aws_region}:${local.aws_account_id}:project/${var.codebuild_project_name}"]
    }
  }

  dynamic "statement" {
    for_each = local.enable_codebuild ? tolist([1]) : []
    content {
      actions = [
        "logs:GetLogEvents",
      ]
      resources = ["arn:${var.aws_partition}:logs:${var.aws_region}:${local.aws_account_id}:log-group:/aws/codebuild/${var.codebuild_project_name}:*"]
    }
  }

# Deploy via ECS
# https://github.com/aws-actions/amazon-ecs-deploy-task-definition
  dynamic "statement" {
    for_each = local.enable_ecs ? tolist([1]) : []
    content {
      actions = [
        "ecs:RegisterTaskDefinition"
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = local.enable_ecs ? tolist([1]) : []
    content {
      actions = [
        "iam:PassRole"
      ]
      resources = concat(local.ecs_task_roles, local.ecs_execution_roles)
    }
  }

  dynamic "statement" {
    for_each = local.enable_ecs ? tolist([1]) : []
    content {
      actions = [
        "ecs:UpdateService",
        "ecs:DescribeServices"
      ]
      resources = local.ecs_service_arns
    }
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

  # Create CodeDeploy deployment
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
      resources = local.ecs_codedeploy_arns
    }
  }

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

  # KMS
  # https://docs.aws.amazon.com/kms/latest/developerguide/kms-api-permissions-reference.html
  # https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
  # https://repost.aws/knowledge-center/s3-access-denied-error-kms
  dynamic "statement" {
    for_each = local.kms_key_arn == null ? [] : tolist([1])
    content {
      sid = "AllowKeyUsage"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      resources = [local.kms_key_arn]
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

# Base IAM role
resource "aws_iam_role" "this" {
  name               = local.role_name
  description        = "Allow GitHub Action to call AWS services"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_policy" "this" {
  name = local.policy_name
  # name_prefix = "${local.name}-${var.comp}-ecs-task-"
  description = "Access resources from GitHub Action"
  policy      = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
