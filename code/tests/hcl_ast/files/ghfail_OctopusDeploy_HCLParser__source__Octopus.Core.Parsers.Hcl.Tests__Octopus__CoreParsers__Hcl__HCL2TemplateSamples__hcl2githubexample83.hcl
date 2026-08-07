resource "aws_iam_role" "automation" {
  assume_role_policy = data.aws_iam_policy_document.automation_assume_role.json
  name               = "${var.name}-wireguard-automation-${data.aws_region.current.name}"
}

resource "aws_iam_role_policy_attachment" "automation" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
  role       = "${var.name}-wireguard-automation-${data.aws_region.current.name}"
}

resource "aws_iam_role" "events" {
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json
  name               = "${var.name}-wireguard-events-${data.aws_region.current.name}"
}

resource "aws_iam_role_policy" "automation_invoke" {
  policy = data.aws_iam_policy_document.allow_automation_invoke.json
  role = aws_iam_role.events.id
}

resource "aws_cloudwatch_event_rule" "catch_wireguard_instance" {
  name     = "capture-wireguard-instance-launch"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance Launch Successful",
    "EC2 Instance-launch Lifecycle Action"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "${var.autoscaling_group_name}"
    ]
  }
}
PATTERN
}

resource "aws_iam_role_policy" "automation_actions" {
  role = aws_iam_role.automation.id
  policy = data.aws_iam_policy_document.automation_actions.json
}

resource "aws_cloudwatch_event_target" "automation" {
  arn = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.self.account_id}:automation-definition/${aws_ssm_document.register_wireguard_dns.name}:$DEFAULT"
  rule = aws_cloudwatch_event_rule.catch_wireguard_instance.name
  target_id = "register-wireguard-dns"
  role_arn = aws_iam_role.events.arn

  input_transformer {
    input_paths    = {
      "instanceId" = "$.detail.EC2InstanceId"
    }
    input_template = "{\"instanceId\": [<instanceId>]}"
  }
}

resource "aws_ssm_document" "register_wireguard_dns" {
  name = "registerWireguardDNS"
  document_type = "Automation"
  document_format = "YAML"
  content = <<DOC
---
description: Register regional Wireguard VPN
schemaVersion: "0.3"
assumeRole: "${aws_iam_role.automation.arn}"
parameters:
  instanceId:
    type: String
    description: The ID of the Wireguard instance.
    default: ""
mainSteps:
- name: GetLaunchedInstance
  action: aws:executeAwsApi
  inputs:
    Service: ec2
    Api: DescribeInstances
    InstanceIds:
      - "{{ instanceId }}"
  outputs:
    - Name: PublicIp
      Selector: "$.Reservations[0].Instances[0].PublicIpAddress"
      Type: String
- name: RegisterWireguardDNS
  action: aws:executeAwsApi
  inputs:
    Service: route53
    Api: ChangeResourceRecordSets
    HostedZoneId: ${var.hosted_zone_id}
    ChangeBatch:
      Comment: Updates the regional Wireguard record
      Changes:
        - Action: UPSERT
          ResourceRecordSet:
            Name: vpn.${data.aws_region.current.name}.${var.domain_name}
            Type: A
            TTL: 60
            ResourceRecords:
              - Value: "{{ GetLaunchedInstance.PublicIp }}"
  isEnd: true
DOC
}