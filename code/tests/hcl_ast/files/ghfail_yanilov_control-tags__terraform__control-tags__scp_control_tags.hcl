locals {

  invalid = {
    identity      = "nil"
    ctl_tag_value = "nil"
  }

  stacksets_exec_role_pattern = "arn:aws:iam::*:role/stacksets-exec-*"
  excluded_principal_patterns = [
    local.stacksets_exec_role_pattern
  ]

  # tag keys that are used to identify the human identity of the caller principal
  human_identity_tag_keys = [
    "aws:SourceIdentity",
  ]

  sids_map = {
    ctl_no_grant             = "CT00"
    ctl_outside_grant        = "CT01"
    ctl_lookalike            = "CT02"
    anti_invalid_identity    = "CT03"
    anti_impersonate_non_sso = "CT04"
    anti_impersonate_sso     = "CT05"
    anti_non_human           = "CT06"
    anti_reflexive           = "CT07"
    anti_forge               = "CT08"

    seal_op_no_approval   = "CTRS0"
    seal_op_outside_grant = "CTRS1"
  }

  sid_selector = {
    short = local.sids_map
    long  = { for k, v in local.sids_map : k => replace(title(replace(k, "_", " ")), " ", "") }
    none  = { for k, v in local.sids_map : k => null }
  }
  sids = local.sid_selector[var.emit_scp_sids]
}

data "aws_iam_policy_document" "control_tags" {
  statement {
    sid       = local.sids.ctl_no_grant
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    # the request contains a control tag
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:TagKeys"
      values   = ["${local.control_prefix}*"]
    }
    # the calling principal does not have a grant area control tag
    condition {
      test     = "Null"
      variable = "aws:PrincipalTag/${local.grant_area_tag_key}"
      values   = ["true"]
    }
    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = local.excluded_principal_patterns
    }
  }

  statement {
    sid       = local.sids.ctl_outside_grant
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    # the request contains a control tag
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:TagKeys"
      values   = ["${local.control_prefix}*"]
    }
    # a control tag in the request falls outside the calling principal's grant area.
    # well-known tag names are added in this condition s.t. IAC systems such as terraform
    # will by able to apply resources with a combination of control and non-conrol tags in a single API call.
    condition {
      test     = "ForAnyValue:StringNotLike"
      variable = "aws:TagKeys"
      values = concat(
        [
          "$${aws:PrincipalTag/${local.grant_area_tag_key}, '${local.invalid.ctl_tag_value}'}",
          "$${aws:PrincipalTag/${local.grant_area_tag_key}, '${local.invalid.ctl_tag_value}'}/*"
        ],
        var.well_known_tag_keys
      )
    }
    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = local.excluded_principal_patterns
    }
  }
  # protect against tagctl prefix lookalikes, like "tagctl/" or "tagctl-"
  statement {
    sid       = local.sids.ctl_lookalike
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:TagKeys"
      values   = local.disallowed_control_prefix_lookalikes
    }
  }
}

data "aws_iam_policy_document" "multiparty_approval" {
  # the principal attempts to set a reserved "nil" value as source identity.
  # this is a reserved value that is used to indicate that the caller principal  does not have a source identity.
  statement {
    sid       = local.sids.anti_invalid_identity
    effect    = "Deny"
    actions   = ["sts:SetSourceIdentity"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "sts:SourceIdentity"
      values   = [local.invalid.identity]
    }
  }
  # non-sso principal attempts to set source identity without being authorized as an identity broker
  statement {
    sid       = local.sids.anti_impersonate_non_sso
    effect    = "Deny"
    actions   = ["sts:AssumeRole*"]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "sts:SourceIdentity"
      values   = ["false"]
    }
    condition {
      test     = "StringNotEqualsIfExists"
      variable = "aws:PrincipalTag/${local.identity_broker_tag_key}"
      values   = ["true"]
    }
    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*"]
    }
  }
  # sso principal attempts to set source identity which does not match its the role session name component in tis aws:userid
  statement {
    sid       = local.sids.anti_impersonate_sso
    effect    = "Deny"
    actions   = ["sts:AssumeRole*"]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "sts:SourceIdentity"
      values   = ["false"]
    }
    condition {
      test     = "StringNotLikeIfExists"
      variable = "aws:userid"
      # sso principal must set its session name as source identity,
      # relying on the identity broker to always set it to the same value
      values = ["*:$${sts:SourceIdentity, '${local.invalid.identity}'}"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*"]
    }
  }
  # An mpa ticket can only be set by principals with human identity.
  statement {
    sid    = local.sids.anti_non_human
    effect = "Deny"
    # unsetting a ticket is allowed (but goverened by control tags)
    not_actions = ["iam:Untag*"]
    resources   = ["*"]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:TagKeys"
      values   = ["${local.mpa_tag_key}/*"]
    }
    condition {
      test     = "Null"
      variable = "aws:SourceIdentity"
      values   = ["true"]
    }
  }
  # Limit the “receiver section” of the tag’s value to anything but the current principal’s identity.
  statement {
    sid    = local.sids.anti_reflexive
    effect = "Deny"
    #note: originally actions = ["iam:TagUser", "iam:CreateUser", "iam:TagRole", "iam:CreateRole"]. is * too restrictive? it could pave the way for resource-based approvals
    actions   = ["*"]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/${local.approval_ticket_tag_key}"
      values   = ["false"]
    }
    condition {
      test     = "StringLikeIfExists"
      variable = "aws:RequestTag/${local.approval_ticket_tag_key}"
      values = [for tag_key in local.human_identity_tag_keys :
        "*/for/$${${tag_key}, '${local.invalid.identity}'}"
      ]
    }
  }
  # Limit the “giver section” of the tag’s value to be just the current principal’s identity.
  statement {
    sid    = local.sids.anti_forge
    effect = "Deny"
    #note: originally actions = ["iam:TagUser", "iam:CreateUser", "iam:TagRole", "iam:CreateRole"]. is * too restrictive? it could pave the way for resource-based approvals
    actions   = ["*"]
    resources = ["*"]
    #a the request attempts to tag an approval ticket
    condition {
      test     = "Null"
      variable = "aws:RequestTag/${local.approval_ticket_tag_key}"
      values   = ["false"]
    }
    # the approval ticket names the something that is NOT the calling principal as the giver
    condition {
      test     = "StringNotLikeIfExists"
      variable = "aws:RequestTag/${local.approval_ticket_tag_key}"
      values = [for tag_key in local.human_identity_tag_keys :
        "by/$${${tag_key}, '${local.invalid.identity}'}/*"
      ]
    }
  }
}

data "aws_iam_policy_document" "trusted_stacksets_exec" {
  statement {
    sid    = "CFTSSE"
    effect = "Deny"
    #not_actions = ["iam:Get*", "iam:List*", "sts:AssumeRole"]
    not_actions = ["iam:Get*", "iam:List*"]
    resources   = [local.stacksets_exec_role_pattern]

    # this condition is commented out on purpose.
    # Since both the org admin and member roles are AWS service roles,  they are unaffected by SCPs
    # condition {
    #   test     = "ArnNotLike"
    #   variable = "aws:PrincipalArn"
    #   values = [
    #     "arn:aws:iam::$${aws:ResourceAccount}:role/aws-service-role/member.org.stacksets.cloudformation.amazonaws.com/AWSServiceRoleForCloudFormationStackSetsOrgMember",
    #     "arn:aws:iam::$${aws:PrincipalOrgMasterAccountId}:role/aws-service-role/stacksets.cloudformation.amazonaws.com/AWSServiceRoleForCloudFormationStackSetsOrgAdmin"
    #   ]
    # }
  }
}

locals {
  # must be set or unset to gether within the same request
  entangled_seal_tags = [local.resource_seal_kind_tag_key, local.resource_seal_grant_tag_key]

  builtin_resource_seal_kinds = {
    total = {
      sid     = "CTRSKB0"
      actions = ["*"]
    }
    trust_relay = {
      sid         = "CTRSKB1"
      not_actions = ["iam:Get*", "iam:List*", "sts:*"]
    }
  }
}

data "aws_iam_policy_document" "resource_seals_core" {
  # deny seal-breaing requests(tag/untag), unless the principal has approval
  statement {
    sid       = local.sids.seal_op_no_approval
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    # request involves tagging/untagging
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "aws:TagKeys"
      values   = ["${local.resource_seal_tag_key}/*"]
    }
    condition {
      test     = "StringNotLikeIfExists"
      variable = "aws:PrincipalTag/${local.approval_ticket_tag_key}"
      values = [for tag_key in local.human_identity_tag_keys :
        "*/for/$${${tag_key}, '${local.invalid.identity}'}"
      ]
    }
  }
  # deny sealing with a grant outside the principal's grant area
  statement {
    sid       = local.sids.seal_op_outside_grant
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/${local.resource_seal_grant_tag_key}"
      values   = ["false"]
    }
    condition {
      test     = "StringNotLikeIfExists"
      variable = "aws:RequestTag/${local.resource_seal_grant_tag_key}"
      values = [
        "$${aws:PrincipalTag/${local.grant_area_tag_key}, '${local.invalid.ctl_tag_value}'}",
        "$${aws:PrincipalTag/${local.grant_area_tag_key}, '${local.invalid.ctl_tag_value}'}/*"
      ]
    }
  }
}


data "aws_iam_policy_document" "resource_seals_kinds" {
  for_each = local.builtin_resource_seal_kinds
  statement {
    sid         = each.value.sid
    effect      = "Deny"
    actions     = try(each.value.actions, null)
    not_actions = try(each.value.not_actions, null)
    resources   = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/${local.resource_seal_kind_tag_key}"
      values   = [each.key]
    }
    condition {
      test     = "StringNotLikeIfExists"
      variable = "aws:PrincipalTag/${local.approval_ticket_tag_key}"
      values = [for tag_key in local.human_identity_tag_keys :
        "*/for/$${${tag_key}, '${local.invalid.identity}'}"
      ]
    }
  }
}


data "aws_iam_policy_document" "unified" {
  source_policy_documents = concat(
    [
      data.aws_iam_policy_document.control_tags.json,
      data.aws_iam_policy_document.multiparty_approval.json,
      data.aws_iam_policy_document.trusted_stacksets_exec.json,
      data.aws_iam_policy_document.resource_seals_core.json,
    ],
    [for _, doc in data.aws_iam_policy_document.resource_seals_kinds : doc.json]
  )
}

resource "aws_organizations_policy" "control_tags" {
  name        = "control_tags"
  type        = "SERVICE_CONTROL_POLICY"
  description = "Scalable tag-based integrity and multi-party approval."
  content     = data.aws_iam_policy_document.unified.minified_json
}

# attach the control tags SCP to all deployment targets
resource "aws_organizations_policy_attachment" "control_tags" {
  for_each = toset(flatten(values(var.deployment_targets)))

  # the SCP must be attached after the mirror roles have been set up
  depends_on = [aws_cloudformation_stack_set.mirror_role]

  policy_id = aws_organizations_policy.control_tags.id
  target_id = each.value
}
