---
title: Cost in the console
description: Use the Costs section of the Stategraph console for a tenant overview, a cost explorer, the analysis of each state, and billing connections.
order: 7
---


The **Costs** section of the console shows the same cost data as the [CLI and API](/docs/infrastructure-as-a-database/cost). Its working pages are **Overview**, **Explorer**, **Analysis**, and **Billing connections**.

When the server has cost analysis off, the cost pages show a notice with a link to the docs, in place of data. See [Enable cost estimation](/docs/admin/self-hosting/cost).

## Basis

Each cost page shows cost on one of these bases:

- **Estimated**: projected monthly cost from list prices, as the [state](/docs/infrastructure-as-a-database/cost/state-cost) and [tenant](/docs/infrastructure-as-a-database/cost/attribution) endpoints return it.
- **Actual**: billed spend from your [FOCUS billing exports](/docs/infrastructure-as-a-database/cost/billing-sources). It is empty until a billing source has synced.
- **Both**: the estimates and the billed actuals, compared.

## Overview

The **Overview** page shows the [tenant rollup and history](/docs/infrastructure-as-a-database/cost/attribution):

- Total monthly and hourly cost, priced states, pricing coverage, and resource count.
- A cost trend over a period, grouped by provider, resource type, or tag key.
- The biggest increases and decreases over the period.
- The cost of each state.

## Explorer

The **Explorer** page slices tenant cost by one dimension at a time: provider, resource type, tag key, or state. For each value, it shows the share of the total and the change over the selected range. These are the `by_provider`, `by_type`, and `by_tag` breakdowns.

## Analysis

The **Analysis** page prices one state:

- The latest monthly estimate and the snapshot time.
- Pricing coverage, with a warning when some resources have no pricing.
- The cost history of the state over a range.
- The per-resource breakdown from the [state cost API](/docs/infrastructure-as-a-database/cost/state-cost).
- With a billing source connected: the actual run rate against the estimated monthly cost, and the number of billing lines and resources matched to the state.

**Recalculate** queues a fresh estimate, like `stategraph cost calculate`.

## Billing connections

The **Billing connections** page manages the [FOCUS billing sources](/docs/infrastructure-as-a-database/cost/billing-sources) of a tenant, which load your actual cloud spend. Like the CLI billing-source commands, the page is for the administrators of the tenant.

## Next steps

- [Cost intelligence](/docs/infrastructure-as-a-database/cost): cost in the CLI, API, and SQL.
- [State and resource cost](/docs/infrastructure-as-a-database/cost/state-cost): the data behind Analysis.
- [Cloud billing (FOCUS)](/docs/infrastructure-as-a-database/cost/billing-sources): billing sources.
