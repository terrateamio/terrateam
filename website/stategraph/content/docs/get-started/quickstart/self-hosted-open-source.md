---
title: Self-hosted Open Source
description: Run Stategraph Orchestration Open Source with Docker Compose, connect GitHub or GitLab, and get your first plan on a pull request.
order: 3
---


Run the open-source edition of Stategraph Orchestration on your own host with Docker Compose, connect GitHub or GitLab, and get your first plan and apply on a pull request.

The open-source edition is the `ghcr.io/terrateamio/terrat-oss` image, built from the [stategraph/stategraph](https://github.com/stategraph/stategraph) repository under the MPL-2.0 license. It runs Orchestration only: pull request plans and applies, policy checks, cost estimates, and drift detection. It does not include Infrastructure as a Database, and it allows up to 3 active users per month per GitHub or GitLab installation, with unlimited runs. See [Editions](/docs/get-started/editions).

An open-source build of the Stategraph server, with Orchestration and no license key, is in development. Until it ships, this page is the open-source path. For Kubernetes or Amazon ECS, and for the variables and metrics of the container, see [Open Source](/docs/admin/self-hosting/open-source). For the Enterprise build, see [Self-hosted Enterprise](/docs/get-started/quickstart/self-hosted).

## Before you begin

- Docker Engine 20.10 or later, and Docker Compose v2.
- Port 3000 free on the host, for the setup wizard.
- For GitHub, admin rights in the GitHub organization, to create and install a GitHub App.
- For GitLab, a group (personal namespaces are not supported), a personal access token with the `api` scope, and the rights to create an OAuth application and add a project webhook.

The server needs no public URL of its own. The setup below connects it to a tunnel that gives it a public HTTPS address, so GitHub or GitLab can reach it from any host.

## 1. Get the Compose files

```bash
git clone https://github.com/stategraph/stategraph.git
cd stategraph/docker/terrat
```

`docker-compose.yml` defines four services: `setup`, the wizard; `db`, PostgreSQL; `server`, the Orchestration server; and `terratunnel`, the tunnel client.

## 2. Run the setup wizard

1. Start the wizard:

```bash
docker compose up setup
```

The `setup` service runs the `ghcr.io/stategraph/orchestration-setup` image. To run the wizard without Compose, for example for a Kubernetes or ECS deployment:

```bash
docker run --rm -p 3000:3000 ghcr.io/stategraph/orchestration-setup:latest
```

To preset the GitHub organization that owns the App, set `GH_ORG`, for example `GH_ORG=acme docker compose up setup`. For GitHub Enterprise Server, set `GHE_HOST` to its host name.

2. Open [http://localhost:3000](http://localhost:3000). The welcome page asks for optional contact details. Select **Next**.
3. Choose GitHub or GitLab.
4. On the **Configure Access** step, keep **Use Terratunnel** and sign in with your GitHub or GitLab account. This provisions the tunnel that gives the server its public URL. The other option, **I have a public server**, is for a deployment with its own URL, such as [Kubernetes](/docs/admin/self-hosting/open-source/kubernetes) or [Amazon ECS](/docs/admin/self-hosting/open-source/ecs). This Compose file expects the tunnel.
5. Finish the provider setup:
    - GitHub: on the **Create App** step, enter the organization that owns the App, or leave it empty for your personal account, and select **Create GitHub application**. GitHub asks you to confirm, and the wizard creates the App with the permissions, webhook, and credentials that Orchestration needs.
    - GitLab: create a dedicated GitLab user for Stategraph. On the **GitLab Setup** step, enter your GitLab instance URL and a personal access token of that user with the `api` scope. Then, as that user, add an application in **Preferences > Applications** with the `api` scope and the redirect URI that the wizard shows, and enter its application ID and secret.

Keep the wizard's final page open until the server runs. It holds the settings for `.env` and the steps to finish on GitHub.

## 3. Write `.env`

Copy the settings block from the wizard's final page into a file named `.env`, next to `docker-compose.yml`. The `setup` container has no volume, so the file must be copied by hand.

For GitHub, the block holds `GITHUB_APP_ID`, `GITHUB_APP_CLIENT_ID`, `GITHUB_APP_CLIENT_SECRET`, `GITHUB_APP_PEM`, `GITHUB_WEBHOOK_SECRET`, and `GITHUB_APP_URL`. For GitLab, it holds `GITLAB_APP_ID`, `GITLAB_APP_SECRET`, and `GITLAB_ACCESS_TOKEN`. Both hold `TERRATUNNEL_API_KEY`, and `TERRAT_UI_BASE` and `TERRAT_WEB_BASE_URL` set to the tunnel URL. The server derives `TERRAT_API_BASE` from the tunnel when it is unset.

## 4. Start the server

1. Stop the wizard with Ctrl+C.
2. Start the database, the tunnel client, and the server:

```bash
docker compose up -d server
```

3. Wait until `docker compose ps` shows the `server` container as `healthy`. To follow the log:

```bash
docker compose logs -f server
```

## 5. Finish the GitHub App

Skip this section for GitLab.

1. Open the App on GitHub, at the `GITHUB_APP_URL` from `.env`, and select **App settings**.
2. Turn on **Request user authorization (OAuth) during installation**.
3. Set the callback URL to `<tunnel-url>/api/github/v1/callback`, and the webhook URL to `<tunnel-url>/api/github/v1/events`, where `<tunnel-url>` is the `TERRAT_UI_BASE` value from `.env`. The tunnel client also updates the webhook URL at start.
4. Save.

Do not install the App on any repository yet. The console does that in the next step.

## Your first pull request

1. Open the console at the `TERRAT_UI_BASE` URL, and sign in with GitHub or GitLab.
2. Follow the **Getting Started** wizard in the console: install the App on your repositories, or connect your GitLab project, and add the workflow file. The file is the same as on Stategraph Cloud: see [Add the workflow file](/docs/get-started/quickstart/cloud#add-the-workflow-file).
3. Open a pull request that changes a `.tf` file, and read the plan comment.
4. Comment `stategraph apply`, then merge.

Plans and applies run on your GitHub Actions or GitLab CI runners. The server only dispatches them.

## Next steps

- [Open Source](/docs/admin/self-hosting/open-source): Kubernetes and Amazon ECS deployments, environment variables, and metrics.
- [Stategraph Cloud](/docs/get-started/quickstart/cloud): the example repository, and what to check when no plan starts.
- [Configuration](/docs/orchestration/configuration): the `.stategraph/config.yml` file.
- [Editions](/docs/get-started/editions): the Open Source limits, and how to get Enterprise.
- [Self-hosted Enterprise](/docs/get-started/quickstart/self-hosted): the Enterprise build of the Stategraph server, with Infrastructure as a Database.
