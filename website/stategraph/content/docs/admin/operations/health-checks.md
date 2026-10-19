---
title: Health checks
description: Use the liveness and readiness endpoints of self-hosted Stategraph, with probe settings for Compose, Kubernetes, ECS, and Cloud Run.
order: 11
---


[Self-hosted Stategraph](/docs/admin/self-hosting) answers two health endpoints on port 8080, which tell load balancers, container orchestrators, and monitoring whether a container is up or ready to serve.

## Endpoints

### Liveness

```http
GET /health/live
```

Returns `200 OK` once Stategraph listens on port 8080, with no check of readiness or of the database.

Use it for:

- ALB target group health checks
- ECS container health checks
- Kubernetes liveness probes

### Readiness

```http
GET /health/ready
```

Returns `200 OK` only when Stategraph is ready to serve requests. Before that, for example during migrations, it returns another status.

Use it for:

- Kubernetes readiness probes
- Load balancer routing to ready instances only
- Monitoring

`/health/ready` does not check Orchestration (see the container log) or cost estimation. Cost estimation answers `200` at `/readyz` on port 8090 inside the container once the price book is loaded.

### Legacy endpoint

```http
GET /api/v1/health
```

It behaves like `/health/ready`, for backward compatibility. For new deployments, use the two endpoints above.

## Startup behavior

Stategraph runs the database migrations before it accepts requests:

```text
t=0   Container starts
t=1   Stategraph listens on port 8080
t=1   /health/live returns 200
t=2   Database migrations begin
t=5+  Migrations complete, server starts
t=5+  /health/ready returns 200
```

During migrations, `/health/live` returns `200` and `/health/ready` returns `502`. A first start on a large database, or an upgrade with many migrations, can take minutes. Allow for this in the probe settings.

## ALB and ECS

### Recommended settings

| Setting | Value | Reason |
|---------|-------|--------|
| Health check path | `/health/live` | Answers at once and during migrations |
| Interval | 30s | Standard |
| Healthy threshold | 2 | Two consecutive successes |
| Unhealthy threshold | 5 | Tolerant during startup |
| Health check grace period | 120s | Time for migrations on the first deployment |

### ECS task definition

```json
{
  "healthCheck": {
    "command": ["CMD-SHELL", "curl -f http://localhost:8080/health/live || exit 1"],
    "interval": 30,
    "timeout": 5,
    "retries": 5,
    "startPeriod": 120
  }
}
```

With a `startPeriod` of 120 seconds, migrations complete before ECS counts failures.

### ALB target group

```hcl
resource "aws_lb_target_group" "stategraph" {
  # ...

  health_check {
    path                = "/health/live"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}
```

### Route traffic only to ready tasks

To keep traffic off a task until it is ready, use `/health/ready` as the target group path, with a higher unhealthy threshold for the migration time:

```hcl
health_check {
  path                = "/health/ready"
  interval            = 30
  timeout             = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10
}
```

## Kubernetes

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 10
```

## Docker Compose

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health/ready"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 120s
```

## Cloud Run

A startup probe on `/health/ready` keeps traffic off a revision until its migrations finish. See [Google Cloud Run](/docs/admin/self-hosting/cloud-run).

## Next steps

- [Observability](/docs/admin/operations/observability): logs and other signals
- [Upgrades](/docs/admin/operations/upgrades): migrations during an upgrade
