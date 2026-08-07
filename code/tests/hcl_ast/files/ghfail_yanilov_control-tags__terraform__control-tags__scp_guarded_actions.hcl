
data "aws_iam_policy_document" "guarded_actions" {
  for_each = var.guarded_action_spec

  statement {
    sid       = "GuardActions"
    effect    = "Deny"
    actions   = each.value.actions
    resources = ["*"]
    condition {
      test     = "StringNotLikeIfExists"
      variable = "aws:PrincipalTag/${local.approval_ticket_tag_key}"
      values   = [for tag_key in local.human_identity_tag_keys : "*/for/$${${tag_key}, '${local.invalid.identity}'}"]
    }
  }
}

resource "aws_organizations_policy" "guarded_actions" {
  for_each = data.aws_iam_policy_document.guarded_actions

  name        = "guarded_actions_${each.key}"
  type        = "SERVICE_CONTROL_POLICY"
  description = "guard actions from being performed without approval."
  content     = each.value.json
}


locals {
  # flatten into tuples of target and policy id
  guarded_actions_attachments = merge([
    for key, spec in var.guarded_action_spec : {
      for target in flatten(values(spec.deployment_targets)) : "${key}/${target}" => {
        target_id = target
        policy_id = aws_organizations_policy.guarded_actions[key].id
      } if target != null
    } if spec.deployment_targets != null
  ]...)
}


resource "aws_organizations_policy_attachment" "guarded_actions" {
  for_each = local.guarded_actions_attachments

  policy_id = each.value.policy_id
  target_id = each.value.target_id
}

check "guarded_actions_without_controltags" {
  assert {
    condition = alltrue([
      for _, attachment in local.guarded_actions_attachments : anytrue([for target_id in toset(flatten(values(var.deployment_targets))) : target_id == attachment.target_id])
    ])
    error_message = "You have attached a guarded action policy to a target in which controltags scp is not attached."
  }
}
