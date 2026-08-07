output "vpc" {
  value = aws_vpc.covidportal
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.covidportal
}

output "ecs_cluster" {
  value = aws_ecs_cluster.covidportal
}

output "route53_zone" {
  value = aws_route53_zone.covidportal
}

output "aws_private_subnets" {
  value = aws_subnet.covidportal_private
}

output "aws_public_subnets" {
  value = aws_subnet.covidportal_public
}

output "security_group_load_balancer" {
  value = aws_security_group.covidportal_load_balancer
}

output "security_group_egress" {
  value = aws_security_group.covidportal_egress
}

output "aws_db_subnet_group" {
  value = aws_db_subnet_group.covidportal
}
