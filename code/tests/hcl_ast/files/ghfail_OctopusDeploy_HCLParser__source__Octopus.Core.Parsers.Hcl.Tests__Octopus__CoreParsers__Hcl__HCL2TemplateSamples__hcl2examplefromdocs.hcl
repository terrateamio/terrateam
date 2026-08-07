data "consul_key_prefix" "environment" {
  path = "apps/example/env"
}

resource "aws_elastic_beanstalk_environment" "example" {
  name        = "test_environment"
  application = "testing"

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  dynamic "setting" {
    for_each = data.consul_key_prefix.environment.var
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
    }
  }
}

output "environment" {
  value = {
    id           = aws_elastic_beanstalk_environment.example.id
    vpc_settings = {
      for s in aws_elastic_beanstalk_environment.example.all_settings :
      s.name => s.value
      if s.namespace == "aws:ec2:vpc"
    }
    vpc_settings2 = [for k, v in var.map : length(k) + length(v)]
    vpc_settings3 = {for s in var.list : substr(s, 0, 1) => s... if s != ""}
    vpc_settings4 = [for o in var.list : o.interfaces[0].name]
  }
}