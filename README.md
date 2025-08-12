<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/terrateamio/brand-artifacts/fa9cb8e10b09478065fc2566e486d4c65d1eb912/logos/wordmark/blue%3Awhite/terrateam_wordmark_blue-white.svg">
    <img alt="Terrateam" src="https://raw.githubusercontent.com/terrateamio/brand-artifacts/fa9cb8e10b09478065fc2566e486d4c65d1eb912/logos/wordmark/blue%3Adark%20blue/terrateam_wordmark_blue-dark%20blue.svg" width="400">
  </picture>
</p>
<p align="center">
  <a href="https://github.com/terrateamio/terrateam/stargazers"><img alt="GitHub Stars" src="https://img.shields.io/github/stars/terrateamio/terrateam"></a>
  <a href="https://terrateam.io/slack"><img alt="Join our Slack" src="https://img.shields.io/badge/slack-join%20chat-blue"></a>
  <a href="https://github.com/terrateamio/mono/releases"><img alt="Latest Release" src="https://img.shields.io/github/v/release/terrateamio/mono?color=%239F50DA"></a>
  <a href="https://ocaml.org"><img alt="OCaml" src="https://img.shields.io/badge/OCaml-EC6813?logo=ocaml&logoColor=fff"></a>
  <a href="https://opensource.org/licenses/MPL-2.0"><img alt="License: MPL-2.0" src="https://img.shields.io/badge/License-MPL--2.0-blue.svg"></a>
</p>

---

## Open-Source Terraform automation in pull requests

Terrateam automates Terraform plans and applies in pull requests. Built from day one to handle thousands of workspaces across monorepos or many repos, with complex dependencies at any scale.

* **GitOps for Scale**: Manage 10 or 10,000 workspaces with tag-based configuration
* **Flexible Automation**: Works with Terraform, OpenTofu, Terragrunt, CDKTF, Pulumi, any CLI
* **Smart Locking**: Apply-only locks mean unlimited parallel plans
* **Policy Engine**: Enforce rules with OPA/Rego, require approvals by team/role
* **Cost & Drift Detection**: Catch infrastructure drift and show cost estimates automatically
* **Self-Hostable**: Stateless by design. Your runners, your state, your secrets

---

<div align="center">
  <img
    src="assets/terrateam-ui.png"
    alt="Terrateam UI - Run Dashboard"
    width="800"
    loading="lazy"
    style="border-radius:8px; border:1px solid #ddd; box-shadow: 0 4px 12px rgba(0,0,0,0.1); margin: 20px 0;"
  >
</div>

### Why Terrateam?

While others built for simple workflows, we engineered for reality:
- **Tag-based configuration** - Define rules once, apply everywhere
- **Monorepo-first** - Handle thousands of workspaces without breaking a sweat
- **Composable policies** - `tag:production AND team:payments` - express complex rules simply
- **Full visibility UI** - Track every run, view execution logs, debug failures - all in the OSS version

[Learn more about our architecture →](https://terrateam.io/monorepo-at-scale)

---

## Try Terrateam

### Hosted SaaS

[Start free →](https://terrateam.io)

### Self-Hosted

#### Quick Start

```bash
# Clone the repository
git clone https://github.com/terrateamio/terrateam
cd terrateam/docker/terrat

# Run the setup
docker-compose up setup

# The Terrateam setup wizard will be available at http://localhost:3000
```
---

## Features

* GitOps pull request automation
* Pre and post-merge applies
* RBAC + OIDC integration
* Policy enforcement (OPA, Rego, Checkov, built-in)
* Cost estimation
* Safe parallel execution with locking
* Cross-environment and dependency coordination
* Config builder for advanced workflows
* Full UI to track runs, view logs, and debug workflows (included in OSS)
* Self-hostable (server and private runners)

---

## Configuration

Configure workflows via `.terrateam/config.yml`. See [Configuration Reference](https://docs.terrateam.io/configuration-reference).

---

## Learn More

* [Monorepo at Scale](https://terrateam.io/monorepo-at-scale) - How we handle thousands of workspaces
* [Technical Architecture](https://terrateam.io/technical-architecture) - The engine under the hood  
* [Configuration Reference](https://docs.terrateam.io/configuration-reference) - Tag queries and advanced workflows
* [Blog](https://terrateam.io/blog) - Updates and best practices

---

## Resources

* [Documentation](https://docs.terrateam.io)
* [Quickstart Guide](https://docs.terrateam.io/getting-started/quickstart-guide)
* [Community Slack](https://terrateam.io/slack)

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) or join our [Slack](https://terrateam.io/slack).

---

## License

Terrateam is MPL-2.0 licensed. The open-source version includes all core features.

Enterprise Edition Features (Hosted SaaS & Self-Hosted Enterprise):
- RBAC - Role-based access control
- Centralized Configuration - Manage config across multiple repos
- Gatekeeper - Advanced approval workflows

These enterprise features are available in our Hosted SaaS or via self-hosted Enterprise Edition licensing.
