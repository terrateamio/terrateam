---
title: Environment variables
description: Every environment variable that the open-source Stategraph Orchestration container reads: database, GitHub, GitLab, URLs, proxy, and CA certificates.
order: 4
---


The environment variables that the Open Source edition of Stategraph Orchestration, the `ghcr.io/terrateamio/terrat-oss` container, reads. You set them in `.env` with [Docker Compose](/docs/get-started/quickstart/self-hosted-open-source), as Secrets and values with the [Helm chart](/docs/admin/self-hosting/open-source/kubernetes), or as Secrets Manager secrets and `extra_environment` with the [ECS module](/docs/admin/self-hosting/open-source/ecs).

For the Enterprise server, `ghcr.io/stategraph/stategraph-server`, see [Environment variables](/docs/admin/operations/environment-variables). Its Orchestration section lists the other `TERRAT_*` settings, such as telemetry and tuning, which the Open Source container reads too.

## Required variables

### Database

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_HOST` | Database host | `localhost`, `db.example.com` |
| `DB_NAME` | Database name | `terrateam` |
| `DB_USER` | Database user | `terrateam` |
| `DB_PASS` | Database password | `secure_password_123` |
| `DB_PORT` | Database port | `5432` |

### GitHub App

Required with GitHub:

| Variable | Description | Example |
|----------|-------------|---------|
| `GITHUB_APP_ID` | GitHub App ID | `123456` |
| `GITHUB_APP_CLIENT_ID` | GitHub App client ID | `Iv1.8ea942184ee41c0b` |
| `GITHUB_APP_CLIENT_SECRET` | GitHub App client secret | `8dab6d1de78a2cdbc9o014dubcf4a55ca44a3c81` |
| `GITHUB_APP_PEM` | GitHub App private key, in PEM format | `-----BEGIN RSA PRIVATE KEY-----\nMIIE...` |
| `GITHUB_WEBHOOK_SECRET` | GitHub webhook secret | `02d87878a0ac61d75d25cz8fec1d1af509f9a6d9` |

### GitLab application

Required with GitLab:

| Variable | Description | Example |
|----------|-------------|---------|
| `GITLAB_APP_ID` | GitLab application ID | `abc123def456` |
| `GITLAB_APP_SECRET` | GitLab application secret | `gloas-1234567890abcdef` |
| `GITLAB_ACCESS_TOKEN` | Personal access token of the bot account | `glpat-xxxxxxxxxxxxxxxxxxxx` |

### Server URLs

| Variable | Description | Example |
|----------|-------------|---------|
| `TERRAT_API_BASE` | Public API base URL, with `/api` | `https://stategraph.example.com/api` |
| `TERRAT_WEB_BASE_URL` | Public web base URL. The base of the run links in comments and commit checks for a repository whose brand has no base of its own | `https://stategraph.example.com` |
| `TERRAT_UI_BASE` | Public console base URL, required for the console. The base of the run links of a `terrateam`-brand repository | `https://stategraph.example.com` |

The setup wizard writes `TERRAT_UI_BASE` and `TERRAT_WEB_BASE_URL`. With the Docker Compose tunnel, the server derives `TERRAT_API_BASE` from the tunnel when it is unset; with your own URL, set it.

## Optional variables

### GitHub Enterprise Server

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `GITHUB_API_BASE_URL` | GitHub API base URL | `https://api.github.com` | `https://github.example.com/api/v3` |
| `GITHUB_WEB_BASE_URL` | GitHub web base URL | `https://github.com` | `https://github.example.com` |

### Self-managed GitLab

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `GITLAB_API_BASE_URL` | Root URL of the instance, without `/api/v4` | `https://gitlab.com` | `https://gitlab.example.com` |
| `GITLAB_WEB_BASE_URL` | Root URL of the instance | `https://gitlab.com` | `https://gitlab.example.com` |

### Proxy

For a network that requires an HTTP proxy:

| Variable | Description | Example |
|----------|-------------|---------|
| `HTTP_PROXY` | URL of the HTTP proxy | `https://proxy.local:8080` |
| `HTTPS_PROXY` | URL of the HTTPS proxy | `https://proxy.local:8080` |
| `NO_PROXY` | Comma-separated hosts that bypass the proxy | `localhost,127.0.0.1,internal.com` |

For a proxy with authentication, put the credentials in the URL:

```bash
HTTP_PROXY=https://username:password@proxy.local:8080
HTTPS_PROXY=https://username:password@proxy.local:8080
```

### Custom CA certificates

For a private certificate authority, such as a TLS-inspecting corporate proxy, a GitHub Enterprise Server with an internal CA, or a private artifact registry, the container installs additional trusted CA certificates into its trust store at start.

| Variable | Description | Example |
|----------|-------------|---------|
| `CUSTOM_CA_CERT` | One or more PEM-encoded CA certificates to install into the system trust store of the container | `-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----` |

When `CUSTOM_CA_CERT` is set, the container parses every `-----BEGIN CERTIFICATE-----` / `-----END CERTIFICATE-----` block from the value, writes each one to `/usr/local/share/ca-certificates/`, and runs `update-ca-certificates`, so the certificates are trusted system-wide inside the container. It removes the custom certificates of a previous start first, so the variable always holds the full set of custom CAs that you want trusted.

When `CUSTOM_CA_CERT` is unset, the container installs nothing and trusts only the certificates of the image.

A single certificate:

```bash
CUSTOM_CA_CERT="-----BEGIN CERTIFICATE-----
MIIDdz...long base64 body...
-----END CERTIFICATE-----"
```

Several certificates, as concatenated PEM blocks. The container splits them:

```bash
CUSTOM_CA_CERT="-----BEGIN CERTIFICATE-----
MIID...root CA...
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIE...intermediate CA...
-----END CERTIFICATE-----"
```

With Docker Compose, load the certificate from a file on the host:

```yaml
services:
  server:
    image: ghcr.io/terrateamio/terrat-oss:latest
    environment:
      CUSTOM_CA_CERT: ${CUSTOM_CA_CERT}
```

```bash
export CUSTOM_CA_CERT="$(cat /path/to/your-ca-bundle.pem)"
docker compose up -d
```

Only PEM certificates are supported. Convert a DER certificate first:

```bash
openssl x509 -inform DER -in your-ca.der -out your-ca.pem
```

## Next steps

- [Observability and metrics](/docs/admin/self-hosting/open-source/observability): when a configuration change has no effect, check `terrat_errors_total` and the other server metrics first.
- [Support](/docs/support): if the metrics do not explain it, contact support with your server logs and your version.
- [Open Source](/docs/admin/self-hosting/open-source): the deployment paths of the open-source edition.
