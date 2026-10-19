---
title: CI and orchestrators
description: Use Infrastructure as a Database under GitHub Actions, GitLab CI, Atlantis, or Spacelift, with no global state lock.
order: 1
---

Infrastructure as a Database works under the tools that already run your Terraform: GitHub Actions, GitLab CI, Atlantis, Spacelift, or another CI system. Your tool still triggers and approves runs. The `stategraph` CLI plans and applies, and Stategraph holds the state, with scoped plans, per-resource conflict detection, and SQL over all your infrastructure.

## Available integrations

- [GitHub Actions](/docs/infrastructure-as-a-database/ci/github-actions): plan on pull requests, apply on merge, with a sticky comment.
- [GitLab CI](/docs/infrastructure-as-a-database/ci/gitlab-ci): plan on merge requests, apply on merge, with a sticky note.
- [Atlantis](/docs/infrastructure-as-a-database/ci/atlantis): keep comment-driven pull request automation, with two run steps for Stategraph.
- [Spacelift](/docs/infrastructure-as-a-database/ci/spacelift): run Stategraph through the Spacelift custom workflow tool.

Other CI systems, such as Jenkins or CircleCI, use the same steps as GitHub Actions and GitLab CI, with no integration. Export the three `STATEGRAPH_*` variables, and replace `terraform plan` and `terraform apply` with `stategraph plan` and `stategraph apply`.

## Stategraph Orchestration

Orchestration is the other way to run Terraform from pull requests. It plans each pull request, enforces policy and approvals, and applies on a comment or on merge, on your GitHub Actions or GitLab CI runners. You write no pipeline YAML. See [Workflows](/docs/orchestration/workflows). With `engine: stategraph`, it plans through Infrastructure as a Database: see [Use with Orchestration](/docs/infrastructure-as-a-database/orchestration).

## Next Steps

- [Setup](/docs/infrastructure-as-a-database/setup): API keys, tenants, and state import.
