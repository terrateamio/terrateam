resource "aws_cognito_user_pool" "user_pool" {
  name = "celsus_user_pool"

  password_policy {
    minimum_length    = "8"
    require_lowercase = "true"
    require_numbers   = "true"
    require_symbols   = "true"
    require_uppercase = "true"
  }

  admin_create_user_config {
    allow_admin_create_user_only = "false"
    unused_account_validity_days = "7"
  }

  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  tags = local.tags
}

resource "aws_cognito_user_pool_client" "client" {
  name                = "celsus_client"
  user_pool_id        = aws_cognito_user_pool.user_pool.id
  explicit_auth_flows = ["USER_PASSWORD_AUTH"]
}

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "celsus_identity_pool"
  allow_unauthenticated_identities = "false"

  cognito_identity_providers {
    provider_name           = aws_cognito_user_pool.user_pool.endpoint
    client_id               = aws_cognito_user_pool_client.client.id
    server_side_token_check = "true"
  }
}

data "template_file" "identity_pool_auth_role_policy" {
  template = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "$${cognito_identity_pool_id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
EOF


  vars = {
    cognito_identity_pool_id = aws_cognito_identity_pool.identity_pool.id
  }
}

resource "aws_iam_role" "identity_pool_auth_role" {
  name = "celsus_identity_authenticated_role"

  assume_role_policy = data.template_file.identity_pool_auth_role_policy.rendered

  tags = local.tags
}

resource "aws_iam_role_policy" "authenticated" {
  name = "celsus_identity_authenticated_policy"
  role = aws_iam_role.identity_pool_auth_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "mobileanalytics:PutEvents",
                "cognito-sync:*",
                "cognito-identity:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF

}

data "template_file" "identity_pool_unauth_role_policy" {
  template = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "$${cognito_identity_pool_id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "unauthenticated"
        }
      }
    }
  ]
}
EOF


  vars = {
    cognito_identity_pool_id = aws_cognito_identity_pool.identity_pool.id
  }
}

resource "aws_iam_role" "identity_pool_unauth_role" {
  name = "celsus_identity_unauthenticated_role"

  assume_role_policy = data.template_file.identity_pool_unauth_role_policy.rendered

  tags = local.tags
}

resource "aws_iam_role_policy" "unauthenticated" {
  name = "celsus_identity_unauthenticated_policy"
  role = aws_iam_role.identity_pool_unauth_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "mobileanalytics:PutEvents",
                "cognito-sync:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF

}

resource "aws_cognito_identity_pool_roles_attachment" "identity_pool_roles_main" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id

  roles = {
    "authenticated"   = aws_iam_role.identity_pool_auth_role.arn
    "unauthenticated" = aws_iam_role.identity_pool_unauth_role.arn
  }
}