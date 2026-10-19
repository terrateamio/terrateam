---
title: Enable cost estimation
description: Turn on cost estimation in self-hosted Stategraph, give the price book a database, verify it, and mirror it for air gaps.
order: 7
---


To turn on cost estimation in [self-hosted Stategraph](/docs/admin/self-hosting), set `STATEGRAPH_COST_ENABLED=true` and give the price book a database. Cost estimation is off by default. It prices each resource from the price book: cloud pricing data in a `cloud_pricing` PostgreSQL database, apart from the `stategraph` database.

## Enable cost

Set `STATEGRAPH_COST_ENABLED=true` in the Stategraph container environment, with your other `STATEGRAPH_*` variables, then recreate the container. The switch is in your deployment configuration, not in a running container, so cost estimation survives redeploys, restarts, pod reschedules, and task replacements.

### Docker Compose

```bash
# .env
STATEGRAPH_COST_ENABLED=true
```

```bash
docker compose up -d
```

See [Docker Compose](/docs/admin/self-hosting/docker-compose).

### Kubernetes and Amazon ECS

Set the same variable in your Helm values or the task definition container `environment`, and roll out the change. See [Kubernetes](/docs/admin/self-hosting/kubernetes) and [Amazon ECS](/docs/admin/self-hosting/ecs).

### The pricing database

Cost estimation connects with `PRICING_DB_*`, not `DB_*`. The defaults match the Docker Compose PostgreSQL. On any other setup, set at least `PRICING_DB_HOST` and `PRICING_DB_PASSWORD`, plus `PRICING_DB_SSLMODE` for a remote server. If not, cost estimation cannot reach the database and never works. [Google Cloud Run](/docs/admin/self-hosting/cloud-run) shows a full example with a sidecar.

The `load-pricing-data` loader also uses `PRICING_DB_*`. When they are unset, it falls back to `DB_HOST`, `DB_PORT`, `DB_USER`, and `DB_PASS`.

### What happens on first boot

With cost on and an empty price book, Stategraph loads the price book into `cloud_pricing` at start. This happens at the first start, and again after the database is wiped.

- The load runs in the background. The server and the console are available at once, and cost figures appear when the load completes.
- The first load downloads a large dataset, several hundred MB compressed and millions of prices. Allow a few minutes, and make sure that the database has space.

## Verify

1. Check that the server has cost estimation on:

```bash
curl -H "Authorization: Bearer $STATEGRAPH_API_KEY" \
  https://stategraph.example.com/api/v1/capabilities
```

```json
{ "costs": { "enabled": true } }
```

If `enabled` is `false`, the server started without `STATEGRAPH_COST_ENABLED=true`, and cost calculation requests return `503`.

2. Check the price book. `/readyz` answers `200` when it is loaded and `503` while it loads, so it also serves as a readiness probe:

```bash
docker compose exec server curl -fsS http://localhost:8090/readyz
```

When both checks pass, produce the first estimate for a state. See [State cost](/docs/infrastructure-as-a-database/cost/state-cost).

## The price book

- Stategraph refreshes the price book on the `PRICING_REFRESH_HOURS` interval, in the background with an atomic swap. Estimates use the previous prices until the new data is ready.
- The price book persists in the database, so it survives restarts. Give `cloud_pricing` durable storage: the `db` volume in Docker Compose, and a managed or volume-backed PostgreSQL on Kubernetes or ECS.

To force a reload, for example after you change `PRICING_DATA_URL`, run the loader in the container:

```bash
docker compose exec server load-pricing-data
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `STATEGRAPH_COST_ENABLED` | off | `true` or `1` turns on cost estimation |
| `STATEGRAPH_PRICING_SERVICE_URL` | `http://localhost:8090` | Pricing endpoint. Set it only for an external pricing service |
| `PRICING_REFRESH_HOURS` | `168` | Price-book reload interval. `0` turns off the automatic refresh |
| `PRICING_DB_HOST` / `PRICING_DB_PORT` | `db` / `5432` | Host and port of the `cloud_pricing` database |
| `PRICING_DB_USER` / `PRICING_DB_PASSWORD` | `stategraph` / `stategraph` | Credentials for the `cloud_pricing` database |
| `PRICING_DB_NAME` | `cloud_pricing` | Name of the price-book database |
| `PRICING_DB_SSLMODE` | `disable` | Set it for a remote pricing database |
| `PRICING_DATA_URL` | the price book that Stategraph hosts | Where the loader downloads `products.csv.gz` from |
| `STATEGRAPH_PRICING_DEFAULT_REGION` | `us-east-1` | Region for a resource that does not specify one |
| `STATEGRAPH_COST_SCHEDULE_HOURS` | `24` | Interval of the scheduled per-state cost recompute |
| `STATEGRAPH_COST_EVENT_DEBOUNCE_HOURS` | `6` | Minimum gap before an apply triggers another recompute |
| `STATEGRAPH_COST_PRICING_CALL_TIMEOUT_SECONDS` | `30` | Timeout of one pricing call |
| `LISTEN_ADDR` | `:8090` | Pricing endpoint listen address. No route on it has authentication: do not publish the port |

See [Environment variables](/docs/admin/operations/environment-variables) for all other settings.

## Air-gapped installs

If the container cannot reach the internet, host `products.csv.gz` on a reachable URL or an internal mirror, and set `PRICING_DATA_URL` to it. The loader uses it for the first load and for each scheduled refresh.

## Next steps

- [Cost](/docs/infrastructure-as-a-database/cost): what the estimates cover and how to read them
- [State cost](/docs/infrastructure-as-a-database/cost/state-cost): price a state and read the breakdown
- [Cost estimation in pull requests](/docs/orchestration/external-tools/infracost): the Orchestration side, on pull requests
