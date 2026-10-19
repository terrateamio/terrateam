---
title: Kubernetes
description: Deploy the Open Source edition of Stategraph Orchestration on Kubernetes with the Helm chart, create its secrets, and connect GitHub or GitLab.
order: 2
---


The Helm chart in [terrateamio/helm-charts](https://github.com/terrateamio/helm-charts) deploys the Open Source edition of Stategraph Orchestration on Kubernetes, with a bundled or external PostgreSQL and an optional ingress. This page takes you from the setup wizard to the first plan on a pull request.

The Open Source edition is the `ghcr.io/terrateamio/terrat-oss` image. It runs Orchestration only, not Infrastructure as a Database, and it allows up to 3 active users per month per GitHub or GitLab installation, with unlimited runs. See [Editions](/docs/get-started/editions) and the [Open Source](/docs/admin/self-hosting/open-source) overview. For one host, use the Docker Compose path: [Self-hosted Open Source](/docs/get-started/quickstart/self-hosted-open-source). For Infrastructure as a Database, deploy the Enterprise edition instead: [Enterprise on Kubernetes](/docs/admin/self-hosting/kubernetes).

## Before you begin

- Kubernetes 1.23 or later, Helm 3 or later, and `kubectl` configured for your cluster.
- A DNS name for the server, `stategraph.example.com` in the examples on this page, and a way to serve it over HTTPS: an ingress controller with a certificate, or a cloud load balancer. GitHub and GitLab deliver webhooks only to a public HTTPS URL, and your CI runners call the same URL.
- A PostgreSQL choice. The chart bundles one PostgreSQL pod with one volume, without replication or backups, for evaluation and small installs. For production, use a managed PostgreSQL server with a `terrateam` database and a `terrateam` role.
- For GitHub, admin rights in the GitHub organization, to create and install a GitHub App.
- For GitLab, a group (personal namespaces are not supported), a personal access token with the `api` scope, and the rights to create an OAuth application and add a project webhook.
- Docker on a workstation, for the setup wizard.

## 1. Run the setup wizard

The wizard creates the GitHub App, or collects the GitLab credentials, and prints the environment variables that the server needs. Run it once, on any computer with a browser:

```bash
docker run --rm -p 3000:3000 ghcr.io/stategraph/orchestration-setup:latest
```

To create the GitHub App under an organization, add `-e GH_ORG=acme`. For GitHub Enterprise Server, also add `-e GHE_HOST=github.example.com`.

1. Open [http://localhost:3000](http://localhost:3000), and follow the wizard.
2. Choose GitHub or GitLab.
3. On the tunnel step, select **Continue without tunnel**. Your ingress gives the server its public URL, so it needs no tunnel. For GitLab, enter the server host name, `stategraph.example.com`, when asked.
4. Finish the provider setup:
    - GitHub: the wizard creates the GitHub App, with the permissions, the webhook secret, and the private key that Orchestration needs. Its webhook URL is a placeholder until you set it in step 4 of this page.
    - GitLab: create a dedicated GitLab user for Stategraph, and enter a personal access token with the `api` scope. Then, as that user, add an application in **Preferences > Applications** with the `api` scope and the redirect URI that the wizard shows, `https://stategraph.example.com/api/v1/gitlab/callback`, and enter its application ID and secret.

The wizard's final page shows the settings as a block of `KEY=value` lines. Copy it into a file named `.env` on the computer where you run `kubectl`. For GitHub, the block holds `GITHUB_APP_ID`, `GITHUB_APP_CLIENT_ID`, `GITHUB_APP_CLIENT_SECRET`, `GITHUB_APP_PEM`, `GITHUB_WEBHOOK_SECRET`, and `GITHUB_APP_URL`. For GitLab, it holds `GITLAB_APP_ID`, `GITLAB_APP_SECRET`, and `GITLAB_ACCESS_TOKEN`. `GITHUB_APP_PEM` is one line, with literal `\n` sequences in place of newlines. Keep it that way: the server changes them back.

## 2. Create the secrets

The chart reads every credential from a Kubernetes Secret in the release namespace. The Secret names and keys below are the chart defaults; the `*SecretName` and `*SecretKey` values in `helm show values terrateamio/terrateam` rename them. Create the namespace, then export the `.env` values into your shell. `GITHUB_APP_PEM` contains spaces, so `source .env` fails on it; export the file line by line instead:

```bash
kubectl create namespace terrateam
while IFS= read -r line || [ -n "$line" ]; do [ -n "$line" ] && export "$line"; done < .env
```

### GitHub

```bash
kubectl create secret generic terrateam-github-app-id -n terrateam \
  --from-literal=id="$GITHUB_APP_ID"
kubectl create secret generic terrateam-github-app-client-id -n terrateam \
  --from-literal=id="$GITHUB_APP_CLIENT_ID"
kubectl create secret generic terrateam-github-app-client-secret -n terrateam \
  --from-literal=secret="$GITHUB_APP_CLIENT_SECRET"
kubectl create secret generic terrateam-github-app-pem -n terrateam \
  --from-literal=pem="$GITHUB_APP_PEM"
kubectl create secret generic terrateam-github-webhook-secret -n terrateam \
  --from-literal=secret="$GITHUB_WEBHOOK_SECRET"
```

### GitLab

```bash
kubectl create secret generic terrateam-gitlab-app-id -n terrateam \
  --from-literal=id="$GITLAB_APP_ID"
kubectl create secret generic terrateam-gitlab-app-secret -n terrateam \
  --from-literal=secret="$GITLAB_APP_SECRET"
kubectl create secret generic terrateam-gitlab-access-token -n terrateam \
  --from-literal=token="$GITLAB_ACCESS_TOKEN"
```

### Database

The server reads the PostgreSQL password from the `terrateam-db-password` Secret. With the bundled PostgreSQL, the same Secret sets the password of the `terrateam` role that it creates. With an external server, it is the password of the role you created there.

```bash
kubectl create secret generic terrateam-db-password -n terrateam \
  --from-literal=password='<postgres-password>'
```

The chart can also create these Secrets from inline values such as `terrateam.config.github.appId` and `terrateam.config.db.password`, as its README shows. Those values end up in the Helm release, so use them for a trial only, and not for a credential whose Secret you already created, or Helm fails with `invalid ownership metadata`.

## 3. Install the chart

```bash
helm repo add terrateamio https://terrateamio.github.io/helm-charts/
helm repo update
```

`terrateam.config.fqdn`, the public host name of the server, is the only value without a default. The chart derives `TERRAT_API_BASE`, `TERRAT_UI_BASE`, and `TERRAT_WEB_BASE_URL` from it as `https://` URLs. The `ingress.*` values below create an ingress for the `nginx` ingress class, with TLS from a cert-manager cluster issuer; step 4 has the other ways to expose the server. Keep the default of one replica for the install, so that the first start migrates the database once.

### GitHub

```bash
helm install terrateam terrateamio/terrateam \
  --namespace terrateam \
  --set terrateam.config.fqdn="stategraph.example.com" \
  --set terrateam.config.github.appUrl="$GITHUB_APP_URL" \
  --set ingress.enabled=true \
  --set ingress.useTls=true \
  --set ingress.annotations."cert-manager\.io/cluster-issuer"="letsencrypt-prod"
```

### GitHub Enterprise Server

Add the API and web URLs of your instance. The API URL ends in `/api/v3`.

```bash
helm install terrateam terrateamio/terrateam \
  --namespace terrateam \
  --set terrateam.config.fqdn="stategraph.example.com" \
  --set terrateam.config.github.appUrl="$GITHUB_APP_URL" \
  --set terrateam.config.github.apiBaseUrl="https://github.example.com/api/v3" \
  --set terrateam.config.github.webBaseUrl="https://github.example.com" \
  --set ingress.enabled=true \
  --set ingress.useTls=true \
  --set ingress.annotations."cert-manager\.io/cluster-issuer"="letsencrypt-prod"
```

### GitLab

Only one provider can be on: the chart refuses to render with both `terrateam.config.github.enabled` and `terrateam.config.gitlab.enabled` set to `true`.

```bash
helm install terrateam terrateamio/terrateam \
  --namespace terrateam \
  --set terrateam.config.fqdn="stategraph.example.com" \
  --set terrateam.config.github.enabled=false \
  --set terrateam.config.gitlab.enabled=true \
  --set ingress.enabled=true \
  --set ingress.useTls=true \
  --set ingress.annotations."cert-manager\.io/cluster-issuer"="letsencrypt-prod"
```

### Self-managed GitLab

Add the root URL of your instance, without `/api/v4`, as both the API and the web URL.

```bash
helm install terrateam terrateamio/terrateam \
  --namespace terrateam \
  --set terrateam.config.fqdn="stategraph.example.com" \
  --set terrateam.config.github.enabled=false \
  --set terrateam.config.gitlab.enabled=true \
  --set terrateam.config.gitlab.apiBaseUrl="https://gitlab.example.com" \
  --set terrateam.config.gitlab.webBaseUrl="https://gitlab.example.com" \
  --set ingress.enabled=true \
  --set ingress.useTls=true \
  --set ingress.annotations."cert-manager\.io/cluster-issuer"="letsencrypt-prod"
```

### External PostgreSQL

Add these values to any of the commands above. Create the `terrateam` database and role on your server first; the chart does not.

```bash
  --set db.enabled=false \
  --set terrateam.config.db.hostname="postgres.internal.example.com" \
  --set terrateam.config.db.port=5432 \
  --set terrateam.config.db.username="terrateam" \
  --set terrateam.config.db.databaseName="terrateam"
```

With either database, an init container waits until PostgreSQL accepts connections before the server starts.

### Watch the rollout

`helm install` lists the Secrets that the release expects and marks any that are missing. A server pod that stays in `CreateContainerConfigError` is missing one of them.

```bash
kubectl rollout status deployment/terrateam-server -n terrateam
```

## 4. Expose the server and set the webhook and callback URLs

### DNS and TLS

Point `stategraph.example.com` at the address of the ingress:

```bash
kubectl get ingress terrateam-ingress -n terrateam
```

With the annotation from step 3, cert-manager stores the certificate in the `terrateam-tls` Secret, which `ingress.tlsSecretName` names. To bring your own certificate instead, leave out the annotation and create the Secret yourself:

```bash
kubectl create secret tls terrateam-tls -n terrateam --cert=tls.crt --key=tls.key
```

### GKE

On Google Kubernetes Engine, use the `gce` ingress class with a global static IP address and a Google-managed certificate. The chart renders the certificate from `ingress.certificate`, with the name `terrateam-ingress-certificate`. Create the address, then put the settings in a values file and pass it with `-f gke-values.yaml` in place of the `ingress.*` flags:

```bash
gcloud compute addresses create stategraph-static-ip --global
gcloud compute addresses describe stategraph-static-ip --global --format='value(address)'
```

```yaml
# gke-values.yaml
ingress:
  enabled: true
  className: gce
  annotations:
    kubernetes.io/ingress.global-static-ip-name: stategraph-static-ip
    networking.gke.io/managed-certificates: terrateam-ingress-certificate
    kubernetes.io/ingress.allow-http: "false"
  certificate:
    enabled: true
    apiVersion: networking.gke.io/v1
    kind: ManagedCertificate
    spec:
      domains:
        - stategraph.example.com
```

Point the DNS name at the static address. The certificate serves once Google has provisioned it; `kubectl describe managedcertificate terrateam-ingress-certificate -n terrateam` shows its status.

### Without an ingress

With `ingress.enabled=false`, the default, the chart creates only the `terrateam-server` Service, a `ClusterIP` on port 8080. Expose it with your own ingress or load balancer, or set `terrateam.service.type` to `NodePort` or `LoadBalancer`, and terminate TLS in front of it. The server must answer at `https://stategraph.example.com` before webhooks work.

### GitHub webhook and callback URLs

1. Open the App on GitHub, at the `GITHUB_APP_URL` from `.env`, and select **App settings**.
2. Turn on **Request user authorization (OAuth) during installation**.
3. Set the callback URL to `https://stategraph.example.com/api/github/v1/callback`, and the webhook URL to `https://stategraph.example.com/api/github/v1/events`. The webhook secret is the one that the wizard generated, so leave it.
4. Save.

Do not install the App on any repository yet. The console does that in the next step.

### GitLab webhook

GitLab webhooks are per project. When you connect a group in the console in the next step, it shows the webhook URL, `https://stategraph.example.com/api/v1/gitlab/events`, and the secret token to add in GitLab.

## 5. First login and first pull request

1. Open `https://stategraph.example.com`, and sign in with GitHub or GitLab.
2. Follow the **Getting Started** wizard in the console: install the App on your repositories, or connect your GitLab group and add the project webhook that it shows, with **Push events**, **Comments**, **Merge request events**, and **Job events** on. Then add the workflow file. The file is the same as on Stategraph Cloud: see [Add the workflow file](/docs/get-started/quickstart/cloud#add-the-workflow-file).
3. Open a pull request that changes a `.tf` file, and read the plan comment.
4. Comment `stategraph apply`, then merge.

Plans and applies run on your GitHub Actions or GitLab CI runners, which call the server at `https://stategraph.example.com`. The server only dispatches them. If no plan starts, see [If no plan starts](/docs/get-started/quickstart/cloud#if-no-plan-starts).

## Operations

### Scale

The server scales horizontally; the database is the limit. The chart's default update strategy is `Recreate`, which stops the old pod before it starts the new one, so that one version at a time talks to the database. With several replicas, switch to `RollingUpdate`:

```bash
helm upgrade terrateam terrateamio/terrateam -n terrateam --reuse-values \
  --set terrateam.replicaCount=3 \
  --set terrateam.strategy.type=RollingUpdate
```

For a HorizontalPodAutoscaler, set `terrateam.autoscaler.enabled=true` with `terrateam.autoscaler.minReplicas` and `terrateam.autoscaler.maxReplicas`; it replaces `terrateam.replicaCount`.

### Upgrade

```bash
helm repo update
helm upgrade terrateam terrateamio/terrateam -n terrateam --reuse-values
```

`--reuse-values` keeps the values from the install; without it, pass them again. `terrateam.image.tag` defaults to `latest`, with `pullPolicy: Always`, so an upgrade or a pod restart pulls the newest image. For production, pin the tag to a version from the [package page](https://github.com/orgs/terrateamio/packages/container/package/terrat-oss), so that `helm rollback` rolls the server back too. Before a chart upgrade, read [UPGRADING.md](https://github.com/terrateamio/helm-charts/blob/main/UPGRADING.md), in particular for a PostgreSQL major version change of the bundled database, and back that database up:

```bash
kubectl exec -n terrateam deploy/terrateam-db -- pg_dumpall -U terrateam > stategraph-backup.sql
```

### Restart

```bash
kubectl rollout restart deployment/terrateam-server -n terrateam
```

The chart restarts the server on its own when a Secret that it created changes. It does not watch the Secrets you created with `kubectl`, so restart after you rotate one of them.

### Logs

```bash
kubectl logs -n terrateam deployment/terrateam-server -f
kubectl get events -n terrateam --sort-by=.lastTimestamp
```

The chart's liveness and readiness probes call `/health` on port 8080.

### Uninstall

```bash
helm uninstall terrateam -n terrateam
```

The chart keeps the PersistentVolumeClaim of the bundled database, `terrateam-db-data-claim`, so the data survives. Delete it by hand when you mean to: `kubectl delete pvc terrateam-db-data-claim -n terrateam`. Set `db.pvc.retain=false` for a test install that `helm uninstall` should remove completely.

## Next steps

- [Configuration](/docs/orchestration/configuration): the `.stategraph/config.yml` file.
- [Environment variables](/docs/admin/self-hosting/open-source/environment-variables): every variable that the container reads. Pass extra ones as a list of `name` and `value` entries in `terrateam.config.extraEnv`.
- [Observability and metrics](/docs/admin/self-hosting/open-source/observability): the health endpoint, logs, and Prometheus metrics.
- [Editions](/docs/get-started/editions): the Open Source limits, and how to get Enterprise.
- [Enterprise on Kubernetes](/docs/admin/self-hosting/kubernetes): the Enterprise chart, with Infrastructure as a Database.
