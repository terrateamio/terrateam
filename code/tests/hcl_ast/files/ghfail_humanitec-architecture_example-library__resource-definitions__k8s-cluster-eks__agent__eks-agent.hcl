resource "humanitec_resource_definition" "eks-agent" {
  driver_type    = "humanitec/k8s-cluster-eks"
  id             = "eks-agent"
  name           = "eks-agent"
  type           = "k8s-cluster"
  driver_account = "aws-temp-creds"
  driver_inputs = {
    values_string = jsonencode({
      "region"                   = "eu-central-1"
      "name"                     = "demo-123"
      "loadbalancer"             = "x111111xxx111111111x1xx1x111111x-x111x1x11xx111x1.elb.eu-central-1.amazonaws.com"
      "loadbalancer_hosted_zone" = "ABC0DEF5WYYZ00"
    })
    secrets_string = jsonencode({
      "agent_url" = "$${resources['agent#agent'].outputs.url}"
    })
  }
}

