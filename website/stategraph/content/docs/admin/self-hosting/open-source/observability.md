---
title: Observability and metrics
description: Prometheus metrics reference for the open-source Stategraph Orchestration server, with sample queries, recommended alerts, and dashboard panels.
order: 5
---


The Open Source edition of Stategraph Orchestration, the `ghcr.io/terrateamio/terrat-oss` container, exposes Prometheus metrics at `/metrics`. This page lists the metrics, with sample queries, alerts, and dashboard panels for operators.

For the Enterprise server, `ghcr.io/stategraph/stategraph-server`, see [Observability](/docs/admin/operations/observability).

## Health endpoint

`GET /health` answers `200` when the server and its database connection are healthy. The Docker Compose file, the Helm chart, and the ECS module use it for their health checks.

## Logs

The server logs to standard output. Read it with your platform: `docker compose logs -f server`, `kubectl logs -n terrateam deployment/terrateam-server -f`, or `aws logs tail /ecs/<name> --follow`.

## Metrics endpoint

All metrics are at:

```text
http://<server-host>/metrics
```

Most metrics use the `terrat` prefix.

## Errors

### `terrat_errors_total`

- **Type**: Counter
- **Labels**: `module`, `type`
- **Description**: Errors across all modules of the server

This is the primary error counter. The labels tell the module and the error type apart.

## Health checks

### `terrat_ep_health_check_duration_seconds`

- **Type**: Histogram
- **Description**: Time of a database health check

### `terrat_ep_health_check_requests_total`

- **Type**: Counter
- **Description**: Total number of health check requests

### `terrat_ep_health_check_responses_total`

- **Type**: Counter
- **Labels**: `result`
- **Description**: Health check outcomes
- **Result values**: `success`, `ping_fail`, `pgsql_pool_fail`

### `terrat_ep_health_check_requests_concurrent`

- **Type**: Gauge
- **Description**: Health check requests in progress

## Database connection pool

### `terrat_storage_num_conns`

- **Type**: Gauge
- **Description**: Total number of PostgreSQL connections created

### `terrat_storage_num_idle_conns`

- **Type**: Gauge
- **Description**: Idle connections in the PostgreSQL connection pool

## GitHub webhook events

### `terrat_ep_github_events_events_duration_seconds`

- **Type**: Histogram
- **Buckets**: `[0.005, 0.5, 1.0, 5.0, 10.0, 15.0, 20.0]`
- **Description**: Time to process an incoming GitHub webhook event, in seconds

### `terrat_ep_github_events_events_total`

- **Type**: Counter
- **Labels**: `type`, `action`
- **Description**: GitHub webhook events received
- **Event types and actions**: type `comment` with actions `not_terrateam`, `tag_query`, `unknown_action`, `noop`; type `pr` with actions `open`, `sync`, `reopen`, `close`, `ready_for_review`; type `installation` with actions `created`, `deleted`, `new_permissions_accepted`, `suspended`, `unsuspended`

### `terrat_ep_github_events_events_concurrent`

- **Type**: Gauge
- **Description**: GitHub webhook events in processing

## GitHub API client

### `terrat_github_call_retries_total`

- **Type**: Counter
- **Description**: Retries of GitHub API calls

### `terrat_github_rate_limit_retry_wait_seconds`

- **Type**: Histogram
- **Buckets**: Exponential (start: 30.0, factor: 1.2, count: 20)
- **Description**: Time spent waiting for a GitHub API rate limit before a retry

### `terrat_github_rate_limit_remaining_count`

- **Type**: Histogram
- **Buckets**: `[100.0, 500.0, 1000.0, 2000.0, 3000.0, 4000.0, 5000.0, 6000.0, 10000.0]`
- **Description**: API calls remaining in the GitHub rate limit window

### `terrat_github_fn_call_total`

- **Type**: Counter
- **Labels**: `fn`
- **Description**: Calls per GitHub API function

## GitHub VCS API

### `terrat_vcs_api_github_cache_fn_call_count`

- **Type**: Counter
- **Labels**: `lifetime`, `fn`, `type`
- **Description**: Cache performance of GitHub API calls
- **Type values**: `hit`, `miss`, `evict`

### `terrat_vcs_api_github_fetch_pull_request_errors_total`

- **Type**: Counter
- **Description**: Errors when fetching pull request data from GitHub

### `terrat_vcs_api_github_pull_request_mergeable_state_count`

- **Type**: Counter
- **Labels**: `mergeable_state`
- **Description**: Distribution of the pull request mergeable states that the GitHub API returns

## GitHub evaluator

### `terrat_github_evaluator_psql_query_time`

- **Type**: Histogram
- **Labels**: `q`
- **Buckets**: Linear (start: 0.0, interval: 0.1, count: 15)
- **Description**: PostgreSQL query time during GitHub event processing

### `terrat_github_evaluator_run_overall_result_count`

- **Type**: Counter
- **Labels**: `success`
- **Description**: Results of the workflow runs started from GitHub

## GitLab webhook events

### `terrat_ep_gitlab_events_events_duration_seconds`

- **Type**: Histogram
- **Buckets**: `[0.005, 0.5, 1.0, 5.0, 10.0, 15.0, 20.0]`
- **Description**: Time to process an incoming GitLab webhook event, in seconds

### `terrat_ep_gitlab_events_events_total`

- **Type**: Counter
- **Labels**: `type`, `action`
- **Description**: GitLab webhook events received

### `terrat_ep_gitlab_events_events_concurrent`

- **Type**: Gauge
- **Description**: GitLab webhook events in processing

## GitLab API client

### `terrat_vcs_api_gitlab_call_retries_total`

- **Type**: Counter
- **Description**: Retries of GitLab API calls

### `terrat_vcs_api_gitlab_rate_limit_retry_wait_seconds`

- **Type**: Histogram
- **Buckets**: Exponential (start: 30.0, factor: 1.2, count: 20)
- **Description**: Time spent waiting for a GitLab API rate limit before a retry

### `terrat_vcs_api_gitlab_rate_limit_remaining_count`

- **Type**: Histogram
- **Buckets**: `[100.0, 500.0, 1000.0, 2000.0, 3000.0, 4000.0, 5000.0, 6000.0, 10000.0]`
- **Description**: API calls remaining in the GitLab rate limit window

### `terrat_vcs_api_gitlab_fn_call_total`

- **Type**: Counter
- **Labels**: `fn`
- **Description**: Calls per GitLab API function

## GitLab provider

### `terrat_vcs_service_gitlab_provider_psql_query_time`

- **Type**: Histogram
- **Labels**: `q`
- **Buckets**: Linear (start: 0.0, interval: 0.1, count: 15)
- **Description**: PostgreSQL query time during GitLab event processing

### `terrat_vcs_service_gitlab_provider_run_overall_result_count`

- **Type**: Counter
- **Labels**: `success`
- **Description**: Results of the workflow runs started from GitLab

## Apply operations

### `terrat_apply_total`

- **Type**: Counter
- **Labels**: `force`
- **Description**: Apply operations started
- **Label values**: `force="true"` for `stategraph apply-force`, `force="false"` for the other applies, including autoapply and the automatic apply of stacks

Example queries:

```text
# Rate of all applies
rate(terrat_apply_total[5m])

# Rate of force applies
rate(terrat_apply_total{force="true"}[5m])

# Share of force applies
rate(terrat_apply_total{force="true"}[1h]) / rate(terrat_apply_total[1h])
```

## Event evaluator

### `terrat_evaluator_op_on_account_disabled_total`

- **Type**: Counter
- **Description**: Operations attempted on disabled accounts

### `terrat_evaluator_access_control_total`

- **Type**: Counter
- **Labels**: `type`, `result`
- **Description**: Access control check results
- **Result values**: `allowed`, `denied`

### `terrat_evaluator_cache_dv_call_count`

- **Type**: Counter
- **Labels**: `v`, `type`
- **Description**: Cache performance of derived values
- **Type values**: `hit`, `miss`, `evict`

## Infracost

### `terrat_ep_infracost_duration_seconds`

- **Type**: Histogram
- **Buckets**: `[0.005, 0.5, 1.0, 5.0, 10.0, 15.0, 20.0]`
- **Description**: Time to process a request of the Infracost API proxy

### `terrat_ep_infracost_requests_total`

- **Type**: Counter
- **Description**: Total number of Infracost API proxy requests

### `terrat_ep_infracost_responses_total`

- **Type**: Counter
- **Labels**: `result`
- **Description**: Infracost API response outcomes
- **Result values**: `success`, `error`, `timeout`

### `terrat_ep_infracost_requests_concurrent`

- **Type**: Gauge
- **Description**: Infracost requests in progress, at most 10

## Terraform version manager (tenv)

### `terrat_ep_tenv_cache_fn_call_count`

- **Type**: Counter
- **Labels**: `lifetime`, `fn`, `type`
- **Description**: Cache performance of Terraform and OpenTofu version downloads
- **Type values**: `hit`, `miss`, `evict`

## Nginx reverse proxy

### `terrat_nginx_active_connections`

- **Type**: Gauge
- **Description**: Active nginx connections

### `terrat_nginx_accepts_count`

- **Type**: Gauge
- **Description**: Cumulative count of accepted nginx connections

### `terrat_nginx_handled_count`

- **Type**: Gauge
- **Description**: Cumulative count of handled nginx connections

### `terrat_nginx_requests_count`

- **Type**: Gauge
- **Description**: Cumulative count of nginx requests

### `terrat_nginx_reading`

- **Type**: Gauge
- **Description**: Nginx connections in the reading state

### `terrat_nginx_writing`

- **Type**: Gauge
- **Description**: Nginx connections in the writing state

### `terrat_nginx_waiting`

- **Type**: Gauge
- **Description**: Nginx connections in the waiting (keepalive) state

## Sample queries

Event processing rate:

```text
rate(terrat_ep_github_events_events_total[5m])
```

Error rate:

```text
rate(terrat_errors_total[5m])
```

P99 event processing latency:

```text
histogram_quantile(0.99, rate(terrat_ep_github_events_events_duration_seconds_bucket[5m]))
```

Median remaining API rate limit:

```text
histogram_quantile(0.50, rate(terrat_github_rate_limit_remaining_count_bucket[5m]))
```

Database connection pool utilization:

```text
(terrat_storage_num_conns - terrat_storage_num_idle_conns) / terrat_storage_num_conns
```

Health check failure rate:

```text
rate(terrat_ep_health_check_responses_total{result!="success"}[5m])
```

## Recommended alerts

### Critical

Health check failures:

```text
rate(terrat_ep_health_check_responses_total{result!="success"}[5m]) > 0
```

High error rate, more than 10 errors per second:

```text
rate(terrat_errors_total[5m]) > 10
```

Database connection pool exhausted:

```text
terrat_storage_num_idle_conns == 0
```

### Warning

GitHub rate limit low, median remaining below 500:

```text
histogram_quantile(0.50, rate(terrat_github_rate_limit_remaining_count_bucket[5m])) < 500
```

High event processing latency, p99 above 10 seconds:

```text
histogram_quantile(0.99, rate(terrat_ep_github_events_events_duration_seconds_bucket[5m])) > 10
```

Event processing backlog:

```text
terrat_ep_github_events_events_concurrent > 50
```

Infracost concurrency limit reached:

```text
terrat_ep_infracost_requests_concurrent >= 10
```

## Dashboard panels

Panels that a Grafana dashboard can start from:

- **System health**: health check success rate (time series), database connection pool status (gauge), error rate by module and type (time series)
- **Event processing**: GitHub and GitLab event rate by type and action (time series), event processing latency p50, p95, and p99 (time series), concurrent events (gauge)
- **API health**: remaining API rate limit for GitHub and GitLab (gauge), API retry rate (time series), API call rate by function (time series)
- **Workflow execution**: run success and failure rate (time series), PostgreSQL query performance (heatmap)
- **Cache performance**: cache hit rates per subsystem (gauge), cache operations by type (time series)

## Notes on collection

- Each histogram has buckets chosen for its use.
- Metrics reset when the server restarts.
- Scrape every 15 to 30 seconds.
- For long-term retention, use Thanos, Cortex, or similar storage.

## Next steps

- [Environment variables](/docs/admin/self-hosting/open-source/environment-variables): every variable that the container reads.
- [Open Source](/docs/admin/self-hosting/open-source): the deployment paths of the open-source edition.
- [Support](/docs/support): what to send when you need help.
