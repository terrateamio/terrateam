---
title: Amazon ECS
description: Deploy the Open Source edition of Stategraph Orchestration on AWS with the Terraform module: ECS Fargate, an Application Load Balancer, and RDS.
order: 3
---


Deploy the Open Source edition of Stategraph Orchestration on AWS with the [terraform-aws-terrateam](https://github.com/terrateamio/terraform-aws-terrateam) Terraform module. It creates an ECS Fargate service behind an Application Load Balancer, with an RDS PostgreSQL database, as infrastructure as code.

The Open Source edition is the `ghcr.io/terrateamio/terrat-oss` image. It runs Orchestration only, not Infrastructure as a Database, and it allows up to 3 active users per month per GitHub or GitLab installation, with unlimited runs. See [Editions](/docs/get-started/editions) and the [Open Source](/docs/admin/self-hosting/open-source) overview. The module connects to GitHub. For GitLab, use [Kubernetes](/docs/admin/self-hosting/open-source/kubernetes) or [Docker Compose](/docs/get-started/quickstart/self-hosted-open-source). For Infrastructure as a Database, deploy the Enterprise edition instead: [Enterprise on Amazon ECS](/docs/admin/self-hosting/ecs).

## Before you begin

- An AWS account with permissions for ECS, RDS, the Application Load Balancer, IAM, Secrets Manager, and CloudWatch.
- Terraform 1.3 or later.
- A VPC with public subnets for the load balancer, at least two in different availability zones, and private subnets with a NAT gateway for the ECS tasks and RDS. Without a NAT gateway, put the tasks in public subnets and set `assign_public_ip = true`.
- A DNS name for the server, `stategraph.example.com` in the examples on this page.
- An ACM certificate for HTTPS. Optional for a trial, but GitHub requires an HTTPS callback URL for the sign-in to the console.
- Admin rights in the GitHub organization, to create and install a GitHub App.
- Docker on a workstation, for the setup wizard.

## Architecture

The module creates:

- An ECS cluster and a Fargate service that runs the server container.
- An Application Load Balancer, with health checks on `/health`.
- An RDS PostgreSQL instance with encrypted storage.
- Secrets Manager secrets for the GitHub App credentials and the database password.
- A CloudWatch log group for the container logs.
- Security groups that restrict the traffic between the load balancer, ECS, and RDS.
- IAM roles for the task execution (pulling the image, reading the secrets) and for the task itself.

## 1. Run the setup wizard

The wizard creates the GitHub App and prints the credentials that the server needs. Run it once, on any computer with a browser:

```bash
docker run --rm -p 3000:3000 ghcr.io/stategraph/orchestration-setup:latest
```

Open [http://localhost:3000](http://localhost:3000), and follow the wizard. Choose GitHub. On the **Configure Access** step, select **I have a public server**, and enter the server host name, `stategraph.example.com`. On the **Create App** step, enter the organization that owns the App, and select **Create GitHub application**.

The wizard's final page shows the settings as a block of `KEY=value` lines: `GITHUB_APP_ID`, `GITHUB_APP_CLIENT_ID`, `GITHUB_APP_CLIENT_SECRET`, `GITHUB_APP_PEM`, `GITHUB_WEBHOOK_SECRET`, and `GITHUB_APP_URL`. Save it as `.env` on the computer where you run Terraform. You need the values in step 5.

## 2. Write the Terraform configuration

Create a directory with a `main.tf`:

```hcl
provider "aws" {
  region = "us-east-1"
}

module "stategraph" {
  source = "github.com/terrateamio/terraform-aws-terrateam"

  vpc_id             = "vpc-0123456789abcdef0"
  public_subnet_ids  = ["subnet-aaa", "subnet-bbb"]
  private_subnet_ids = ["subnet-ccc", "subnet-ddd"]
  domain             = "stategraph.example.com"

  # HTTPS
  # acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx"

  tags = {
    Environment = "production"
  }
}

output "alb_dns_name" {
  value = module.stategraph.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.stategraph.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.stategraph.ecs_service_name
}

output "secret_arns" {
  value = module.stategraph.secret_arns
}

output "terrateam_url" {
  value = module.stategraph.terrateam_url
}
```

If the ECS tasks run in public subnets without a NAT gateway, add `assign_public_ip = true` to the module block, so that the tasks can pull the container image and reach the GitHub API.

## 3. Apply

```bash
terraform init
terraform apply
```

This creates every resource, including the ECS cluster, the load balancer, the RDS instance, and empty Secrets Manager secrets. The RDS instance takes several minutes.

On the first deploy, the ECS task fails its health checks while the database migrations run, for 2 to 5 minutes. The service retries until the migrations complete and the server starts.

## 4. DNS and HTTPS

The DNS name is the URL for the GitHub webhooks, the OAuth callback, and the console. Point it at the load balancer:

```text
stategraph.example.com  CNAME  <alb_dns_name>
```

On Route 53, create an alias record from the `alb_dns_name` and `alb_zone_id` outputs.

For HTTPS, request an [ACM certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html) for the name, set `acm_certificate_arn` in the module block, and run `terraform apply` again. The module adds an HTTPS listener and redirects HTTP to HTTPS. Webhooks work over HTTP, but GitHub requires an HTTPS callback URL for the sign-in to the console.

## 5. Store the credentials in Secrets Manager

The module creates the secrets empty. Fill them with the values from the wizard:

```bash
# The secret ARNs
terraform output secret_arns

# One call per secret
aws secretsmanager put-secret-value \
  --secret-id <github_app_id ARN> \
  --secret-string '<GITHUB_APP_ID>'

aws secretsmanager put-secret-value \
  --secret-id <github_app_client_id ARN> \
  --secret-string '<GITHUB_APP_CLIENT_ID>'

aws secretsmanager put-secret-value \
  --secret-id <github_app_client_secret ARN> \
  --secret-string '<GITHUB_APP_CLIENT_SECRET>'

aws secretsmanager put-secret-value \
  --secret-id <github_webhook_secret ARN> \
  --secret-string '<GITHUB_WEBHOOK_SECRET>'
```

The `GITHUB_APP_PEM` value in `.env` is one line, with literal `\n` sequences in place of newlines. Convert it back before you store it:

```bash
PEM_RAW=$(grep '^GITHUB_APP_PEM=' .env | sed 's/^GITHUB_APP_PEM=//')
printf '%b' "$PEM_RAW" | aws secretsmanager put-secret-value \
  --secret-id <github_app_pem ARN> \
  --secret-string file:///dev/stdin
```

With the private key as a `.pem` file instead, pass the file:

```bash
aws secretsmanager put-secret-value \
  --secret-id <github_app_pem ARN> \
  --secret-string file://private-key.pem
```

!!! warning "Do not source the .env file"
    `source .env` fails on the PEM value, because of its `\n` sequences and its length. Read the values from the file as above. Never commit `.env` to version control.

## 6. Redeploy the service

Force a new deployment, so that the tasks load the secrets:

```bash
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment
```

The new task passes its health checks after 1 to 2 minutes. Follow the container logs in the `/ecs/<name>` log group, or check the health endpoint:

```bash
curl $(terraform output -raw terrateam_url)/health
```

A `200` response means that the server and the database are healthy.

## 7. Set the GitHub App URLs

1. Open the App on GitHub, at the `GITHUB_APP_URL` from `.env`, and select **App settings**.
2. In the **Webhook** section, set the webhook URL to `https://stategraph.example.com/api/github/v1/events`. The secret is the one that the wizard generated.
3. Turn on **Request user authorization (OAuth) during installation**, and set the callback URL to `https://stategraph.example.com/api/github/v1/callback`.
4. Save.

## 8. First login and first pull request

1. Open `https://stategraph.example.com`, and sign in with GitHub.
2. Follow the **Getting Started** wizard in the console: install the App on your repositories, and add the workflow file. The file is the same as on Stategraph Cloud: see [Add the workflow file](/docs/get-started/quickstart/cloud#add-the-workflow-file).
3. Open a pull request that changes a `.tf` file, and read the plan comment.
4. Comment `stategraph apply`, then merge.

Plans and applies run on your GitHub Actions runners, which call the server at `https://stategraph.example.com`. The server only dispatches them.

## Troubleshooting

Follow the container logs:

```bash
aws logs tail /ecs/<name> --region <region> --follow
```

- The task fails at once: a Secrets Manager secret is still empty. An empty secret stops the server at start. See step 5.
- `502` or `503` from the load balancer: the task is still starting, or the database migrations run. Wait 2 to 5 minutes on the first deploy.
- The sign-in redirects to a wrong URL: after a change of `domain`, run `terraform apply`, then force a new deployment (step 6).

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpc_id` | VPC ID | `string` | required |
| `public_subnet_ids` | Public subnet IDs for the load balancer | `list(string)` | required |
| `private_subnet_ids` | Private subnet IDs for ECS and RDS | `list(string)` | required |
| `domain` | Public DNS name of the server | `string` | required |
| `name` | Name prefix for all resources | `string` | `"terrateam"` |
| `acm_certificate_arn` | ACM certificate ARN, for HTTPS | `string` | `null` |
| `container_image` | Container image | `string` | `"ghcr.io/terrateamio/terrat-oss:latest"` |
| `container_cpu` | Fargate CPU units | `number` | `512` |
| `container_memory` | Fargate memory, in MiB | `number` | `1024` |
| `desired_count` | Number of ECS tasks | `number` | `1` |
| `db_instance_class` | RDS instance class | `string` | `"db.t4g.micro"` |
| `db_engine_version` | PostgreSQL version | `string` | `"14.18"` |
| `db_multi_az` | RDS Multi-AZ | `bool` | `false` |
| `db_deletion_protection` | RDS deletion protection | `bool` | `true` |
| `db_backup_retention_period` | RDS backup retention, in days | `number` | `7` |
| `alb_ingress_cidr_blocks` | CIDR blocks allowed to reach the load balancer | `list(string)` | `["0.0.0.0/0"]` |
| `assign_public_ip` | Assign a public IP address to the ECS tasks | `bool` | `false` |
| `extra_environment` | Additional container environment variables | `list(object)` | `[]` |
| `db_skip_final_snapshot` | Skip the final snapshot when RDS is destroyed | `bool` | `false` |
| `tags` | Tags for all resources | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `alb_dns_name` | DNS name of the load balancer |
| `alb_zone_id` | Route 53 zone ID of the load balancer, for alias records |
| `ecs_cluster_name` | ECS cluster name |
| `ecs_service_name` | ECS service name |
| `task_role_arn` | ECS task role ARN, to attach more policies to |
| `db_endpoint` | RDS endpoint |
| `secret_arns` | Map of the Secrets Manager ARNs |
| `terrateam_url` | URL of the server |
| `alb_security_group_id` | Security group ID of the load balancer |
| `ecs_security_group_id` | Security group ID of the ECS tasks |
| `rds_security_group_id` | Security group ID of RDS |

## Updating

To update the container image or change the configuration, edit the module block and apply:

```bash
terraform apply
```

To redeploy the service without a configuration change, for example after a change of a secret value:

```bash
aws ecs update-service \
  --cluster <ecs_cluster_name> \
  --service <ecs_service_name> \
  --force-new-deployment
```

## Next steps

- [Configuration](/docs/orchestration/configuration): the `.stategraph/config.yml` file.
- [Environment variables](/docs/admin/self-hosting/open-source/environment-variables): every variable that the container reads. Pass extra ones in `extra_environment`.
- [Observability and metrics](/docs/admin/self-hosting/open-source/observability): the health endpoint, logs, and Prometheus metrics.
- [Editions](/docs/get-started/editions): the Open Source limits, and how to get Enterprise.
- [Enterprise on Amazon ECS](/docs/admin/self-hosting/ecs): the Enterprise server, with Infrastructure as a Database.
