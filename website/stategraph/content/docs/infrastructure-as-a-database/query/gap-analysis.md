---
title: Gap Analysis
description: Find the AWS and GCP resources that no Terraform state manages, and generate the Terraform code that brings them under management.
order: 6
---


Gap analysis finds the AWS and GCP resources that no Terraform state in Stategraph manages, and generates the Terraform configuration to import them. The Stategraph server reads your cloud with the credentials that you give it.

Unmanaged resources can come from:

- Manual console changes
- Scripts or CLI commands
- Other IaC tools
- Forgotten experiments

## How it works

<figure class="docs-figure">
<div class="docs-diagram-stages">
<div class="docs-why-panel"><p class="docs-why-label">Cloud provider inventory</p><div class="docs-why-states"><span class="docs-why-state">AWS Resource Explorer</span><span class="docs-why-state">GCP Cloud Asset Inventory</span></div></div>
<span class="docs-why-arrow">&rarr;</span>
<div class="docs-why-panel"><p class="docs-why-label">Stategraph</p><div class="docs-why-states"><span class="docs-why-state">inventory</span><span class="docs-why-arrow">vs</span><span class="docs-why-state accent">states</span></div><p class="docs-why-foot">Compares the two.</p></div>
<span class="docs-why-arrow">&rarr;</span>
<div class="docs-why-panel bad"><p class="docs-why-label">Gap report</p><div class="docs-why-states"><span class="docs-why-state fail">S3 bucket</span><span class="docs-why-state fail">IAM role</span><span class="docs-why-state fail">Compute instance</span></div><p class="docs-why-foot">Unmanaged resources.</p></div>
</div>
<figcaption>Stategraph reads the inventory from AWS Resource Explorer or GCP Cloud Asset Inventory.<br> It compares the inventory with your states.<br> The gap report lists the resources that no state manages.</figcaption>
</figure>

## Supported providers

| Provider | Inventory source | Status |
|----------|-----------------|--------|
| AWS | [Resource Explorer](https://docs.aws.amazon.com/resource-explorer/latest/userguide/welcome.html) | Supported |
| GCP | [Cloud Asset Inventory](https://cloud.google.com/asset-inventory/docs/overview) | Supported |
| Azure | Resource Graph | Planned |

## AWS

### Setup requirements

- Resource Explorer on, with at least one index (required)
- An aggregator index, for discovery across regions (recommended)
- A default view (required)
- `AWS_DEFAULT_REGION` on the server: the region for Resource Explorer queries

### Required IAM permissions

To read the inventory:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "resource-explorer-2:Search",
        "resource-explorer-2:ListIndexes",
        "resource-explorer-2:GetDefaultView"
      ],
      "Resource": "*"
    }
  ]
}
```

To generate Terraform configurations (optional), add read access, such as `ReadOnlyAccess`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ],
      "Resource": "*"
    }
  ]
}
```

### Enable Resource Explorer

```bash
# Enable Resource Explorer in current region
aws resource-explorer-2 create-index --type LOCAL

# Create aggregator index (recommended for multi-region)
aws resource-explorer-2 update-index-type \
  --arn "arn:aws:resource-explorer-2:us-east-1:123456789012:index/..." \
  --type AGGREGATOR

# Create default view
aws resource-explorer-2 create-view --view-name default
aws resource-explorer-2 associate-default-view --view-arn "arn:aws:resource-explorer-2:..."
```

### Check configuration

```bash
# Set API base (or use --api-base flag)
export STATEGRAPH_API_BASE=https://stategraph.example.com

stategraph tenant gaps config \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=aws
```

Response:

```json
{
  "provider": "aws",
  "status": "ready",
  "ready_for_gap_analysis": true,
  "ready_for_terraform_import": true,
  "has_aggregator": true,
  "aggregator_region": "us-east-1",
  "indexed_regions": ["us-east-1", "us-west-2", "eu-west-1"],
  "index_count": 3,
  "warnings": []
}
```

## GCP

### Setup requirements

- The Cloud Asset API on
- Cloud Asset Inventory access at the project, folder, or organization level

### Required IAM permissions

To read the inventory:

```bash
# Grant Cloud Asset Viewer role
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member='serviceAccount:SA_EMAIL' \
  --role='roles/cloudasset.viewer'
```

To generate Terraform configurations (optional):

```bash
# Grant Viewer role (read-only access to all resources)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member='serviceAccount:SA_EMAIL' \
  --role='roles/viewer'
```

### Enable Cloud Asset API

```bash
gcloud services enable cloudasset.googleapis.com --project=PROJECT_ID
```

### Scope configuration

| Scope | Environment variable | Coverage |
|-------|---------------------|----------|
| Project | `GOOGLE_CLOUD_PROJECT` | One project |
| Folder | `GOOGLE_CLOUD_FOLDER` | All projects in the folder |
| Organization | `GOOGLE_CLOUD_ORGANIZATION` | Entire organization |

If you set no scope, Stategraph detects it from the Application Default Credentials.

### Check configuration

```bash
# Set API base (or use --api-base flag)
export STATEGRAPH_API_BASE=https://stategraph.example.com

stategraph tenant gaps config \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=gcp
```

Response:

```json
{
  "provider": "gcp",
  "status": "ready",
  "ready_for_gap_analysis": true,
  "ready_for_terraform_import": false,
  "scope_type": "project",
  "scope_id": "projects/my-project",
  "has_org_access": false,
  "warnings": [
    {
      "code": "NO_VIEWER_PERMISSION",
      "message": "Optional: To generate Terraform configurations for unmanaged resources, grant 'roles/viewer' (read-only) to your service account.",
      "fix": "gcloud projects add-iam-policy-binding my-project \\\n  --member='serviceAccount:123456-compute@developer.gserviceaccount.com' \\\n  --role='roles/viewer'"
    }
  ]
}
```

### Supported GCP resource types

The supported types include:

| Service | Resource types |
|---------|---------------|
| Compute Engine | Instances, Disks, Networks, Subnetworks, Firewalls, Load Balancers |
| Cloud Storage | Buckets |
| Cloud SQL | Instances |
| BigQuery | Datasets, Tables |
| IAM | Service Accounts, Roles |
| Cloud Functions | Functions |
| Pub/Sub | Topics, Subscriptions |
| Cloud Run | Services |
| GKE | Clusters, Node Pools |
| Cloud KMS | Key Rings, Crypto Keys |

## Run gap analysis

In the console, Gap Analysis is under **Inventory**. With the CLI:

```bash
# Set API base (or use --api-base flag)
export STATEGRAPH_API_BASE=https://stategraph.example.com

stategraph tenant gaps analyze \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=aws \
  --format=json
```

`--format` sets the output:

- `table` (default): a table and a `Summary: N managed, M unmanaged` line
- `json`: machine-readable output, as in the examples on this page
- `simple`: one tab-separated row per line, no headers

Gap analysis runs in the background. The first call for a provider starts a scan and returns a `running` status:

```json
{
  "status": "running",
  "started_at": "2026-06-26T17:30:00Z"
}
```

When the scan finishes, run the command again to get the result. A `running` response has no `unmanaged_resources` array, so pipe to `jq` only after that. Later calls use the cache:

```json
{
  "summary": {
    "total_aws_resources": 512,
    "managed_by_stategraph": 460,
    "unmanaged": 49,
    "phantom_filtered": 3
  },
  "unmanaged_resources": [
    {
      "arn": "arn:aws:ec2:us-east-1:123456789012:security-group/sg-0abc1234def567890",
      "service": "ec2",
      "resource_type": "ec2:security-group",
      "region": "us-east-1",
      "owning_account_id": "123456789012"
    }
  ],
  "fetched_at": 1705312800
}
```

!!! note "GCP fields"
    GCP returns `total_cloud_resources` in the summary, and `asset_name` and `project_id` on each unmanaged resource. The GCP resource type is in `resource_type`, as for AWS.

## Understanding results

| Metric | Description |
|--------|-------------|
| `total_aws_resources` / `total_cloud_resources` | All resources in the cloud inventory (AWS / GCP) |
| `managed_by_stategraph` | Resources that match a Terraform state |
| `unmanaged` | Resources in no state |
| `phantom_filtered` | Excluded provider-managed resources (see [Phantom resources](#phantom-resources)) |

### Phantom resources

Gap analysis excludes provider-managed resources that you cannot import:

| Provider | Excluded resources |
|----------|--------------------|
| AWS | Default Athena workgroups and catalogs, service-linked IAM roles, default event buses, default S3 Storage Lens dashboards |
| GCP | Default compute service accounts, default VPC networks, default firewall rules |

## Generating Terraform configurations

The server runs OpenTofu (`tofu init`, then `tofu plan -generate-config-out`) to generate `import` blocks and resource configuration. OpenTofu reads each resource with the server's credentials, which need the optional read access in [AWS](#aws) or [GCP](#gcp). In the console, start it from the unmanaged resources on the **Gap Analysis** page.

### Via CLI

List the unmanaged resources with `gaps analyze`, then generate the configuration with `gaps import`:

```bash
# Set API base (or use --api-base flag)
export STATEGRAPH_API_BASE=https://stategraph.example.com

# Get unmanaged resources
stategraph tenant gaps analyze \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=gcp --format=json | jq '.unmanaged_resources' > unmanaged.json

# Generate Terraform configuration
stategraph tenant gaps import \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=gcp \
  unmanaged.json
```

Response:

```json
{
  "generated_hcl": "resource \"google_compute_instance\" \"imported_orphan_vm\" {\n  name         = \"orphan-vm\"\n  machine_type = \"e2-medium\"\n  zone         = \"us-central1-a\"\n  ...\n}\n",
  "import_blocks": "import {\n  to = google_compute_instance.imported_orphan_vm\n  id = \"projects/my-project/zones/us-central1-a/instances/orphan-vm\"\n}\n",
  "provider_hcl": "terraform {\n  required_providers {\n    google = {\n      source  = \"hashicorp/google\"\n      version = \"~> 5.0\"\n    }\n  }\n}\n",
  "supported_count": 1,
  "unsupported_count": 0,
  "unsupported_resources": []
}
```

### Using generated code

1. Save the generated HCL to a `.tf` file.
2. Run `tofu plan` or `terraform plan` to verify.
3. Run `tofu apply` or `terraform apply` to import.

```bash
# Save generated configuration
cat > import.tf << 'EOF'
import {
  to = google_compute_instance.imported_orphan_vm
  id = "projects/my-project/zones/us-central1-a/instances/orphan-vm"
}

resource "google_compute_instance" "imported_orphan_vm" {
  name         = "orphan-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  # ... generated attributes
}
EOF

# Verify and import
tofu plan
tofu apply
```

## Caching

Stategraph caches the results, to prevent rate limiting and reduce API calls:

| Setting | Default | Description |
|---------|---------|-------------|
| Cache TTL | 3 hours | How long results stay in the cache. `GAP_ANALYSIS_CACHE_TTL` sets it in seconds (10800). |
| Cache location | `/var/cache/stategraph/gap-analysis/` | Cache directory |

```bash
# Set API base (or use --api-base flag)
export STATEGRAPH_API_BASE=https://stategraph.example.com

# Use cache (default, fast)
stategraph tenant gaps analyze \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=gcp

# Force fresh scan (slower)
stategraph tenant gaps analyze \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=gcp \
  --source=no-cache
```

`--source=no-cache` starts a new scan and returns `running`: run the command again without it to get the result. In the console, **Refresh** skips the cache. `fetched_at` is the time of the last fetch from the cloud provider.

## Filtering results

### By service

```bash
stategraph tenant gaps analyze \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=gcp --format=json | jq '.unmanaged_resources | map(select(.service == "compute"))'
```

### By region

```bash
stategraph tenant gaps analyze \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=gcp --format=json | jq '.unmanaged_resources | map(select(.region == "us-central1-a"))'
```

### By resource type

```bash
# AWS (resource_type, e.g. "ec2:instance")
stategraph tenant gaps analyze \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=aws --format=json | jq '.unmanaged_resources | map(select(.resource_type == "ec2:instance"))'

# GCP (resource_type, e.g. "compute.googleapis.com/Instance")
stategraph tenant gaps analyze \
  --tenant=550e8400-e29b-41d4-a716-446655440000 \
  --provider=gcp --format=json | jq '.unmanaged_resources | map(select(.resource_type == "compute.googleapis.com/Instance"))'
```

## Troubleshooting

### AWS: No indexes found

```
"warnings": [{"code": "NO_INDEXES", "message": "No Resource Explorer indexes found"}]
```

**Solution**:

- Enable Resource Explorer in at least one region:

```bash
aws resource-explorer-2 create-index --type LOCAL
```

### AWS: No aggregator

```
"warnings": [{"code": "NO_AGGREGATOR", "message": "No aggregator index configured"}]
```

**Solution**:

- Change one index to the aggregator type, for discovery across regions:

```bash
aws resource-explorer-2 update-index-type --arn "INDEX_ARN" --type AGGREGATOR
```

### GCP: Permission denied

```
"warnings": [{"code": "PERMISSION_DENIED", "message": "Permission denied for scope projects/my-project"}]
```

**Solution**:

- Grant the Cloud Asset Viewer role:

```bash
gcloud projects add-iam-policy-binding my-project \
  --member='serviceAccount:YOUR_SA@my-project.iam.gserviceaccount.com' \
  --role='roles/cloudasset.viewer'
```

### GCP: Insufficient OAuth scopes

```
"warnings": [{"code": "INSUFFICIENT_SCOPES", "message": "VM OAuth scopes are insufficient"}]
```

**Solution**:

- Update the VM scopes. The VM must restart:

```bash
gcloud compute instances stop INSTANCE_NAME --zone=ZONE
gcloud compute instances set-service-account INSTANCE_NAME \
  --zone=ZONE --scopes=cloud-platform
gcloud compute instances start INSTANCE_NAME --zone=ZONE
```

### Terraform import fails with permission denied

Gap analysis reads the Cloud Asset API, but a Terraform import needs read permissions on the resources themselves.

**Solution**:

- Grant `roles/viewer` for Terraform operations:

```bash
gcloud projects add-iam-policy-binding my-project \
  --member='serviceAccount:YOUR_SA@my-project.iam.gserviceaccount.com' \
  --role='roles/viewer'
```

## Best practices

- Run the configuration check first to verify permissions, then scan weekly or after deployments.
- Classify each gap as intentional or a concern. Bring unmanaged production resources under control, and record why the others stay unmanaged.
- On GCP, use the organization scope for complete visibility.

## Credential configuration

### AWS credentials

Stategraph uses the standard AWS credential chain:

1. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
2. Shared credentials file (`~/.aws/credentials`)
3. IAM role for Amazon EC2 / ECS task role
4. IAM Roles for Service Accounts (IRSA) in EKS

#### Docker Compose

Option 1. Pass the credentials as environment variables (for development):

```yaml
services:
  server:
    image: ghcr.io/stategraph/stategraph-server:latest
    environment:
      # ... existing config ...
      AWS_ACCESS_KEY_ID: "AKIAIOSFODNN7EXAMPLE"
      AWS_SECRET_ACCESS_KEY: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
      AWS_DEFAULT_REGION: "us-east-1"
      # Optional: for temporary credentials
      # AWS_SESSION_TOKEN: "your-session-token"
```

Option 2. Mount your local AWS credentials directory (recommended for development):

```yaml
services:
  server:
    image: ghcr.io/stategraph/stategraph-server:latest
    environment:
      # ... existing config ...
      AWS_DEFAULT_REGION: "us-east-1"
      # Optional: specify a named profile
      # AWS_PROFILE: "my-profile"
    volumes:
      - ~/.aws:/home/stategraph/.aws:ro
```

Option 3. Keep the credentials in a `.env` file that you do not commit to git:

```bash
# .env
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_DEFAULT_REGION=us-east-1
```

```yaml
services:
  server:
    image: ghcr.io/stategraph/stategraph-server:latest
    env_file:
      - .env
```

#### Kubernetes

Option 1. A Secret with environment variables:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: stategraph
stringData:
  AWS_ACCESS_KEY_ID: "AKIAIOSFODNN7EXAMPLE"
  AWS_SECRET_ACCESS_KEY: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stategraph
  namespace: stategraph
spec:
  template:
    spec:
      containers:
        - name: stategraph
          envFrom:
            - secretRef:
                name: aws-credentials
          env:
            - name: AWS_DEFAULT_REGION
              value: "us-east-1"
```

Option 2. IAM Roles for Service Accounts (IRSA), recommended for EKS:

1. Create an IAM role with the required permissions and a trust policy for your EKS cluster.
2. Annotate the Kubernetes service account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: stategraph
  namespace: stategraph
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/stategraph-gap-analysis
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stategraph
  namespace: stategraph
spec:
  template:
    spec:
      serviceAccountName: stategraph
      containers:
        - name: stategraph
          env:
            - name: AWS_DEFAULT_REGION
              value: "us-east-1"
```

Option 3. EC2 instance profile. On EC2, or with node IAM roles, you need no more configuration. The node IAM role needs the Resource Explorer permissions.

### GCP credentials

Stategraph uses the standard GCP credential chain:

1. `GOOGLE_APPLICATION_CREDENTIALS` environment variable (path to service account JSON)
2. Application Default Credentials (ADC)
3. Compute Engine / GKE metadata server
4. Workload Identity (GKE)

#### Docker Compose

Mount your GCP service account key file and set `GOOGLE_APPLICATION_CREDENTIALS` to its path:

```yaml
services:
  server:
    image: ghcr.io/stategraph/stategraph-server:latest
    environment:
      # ... existing config ...
      GOOGLE_APPLICATION_CREDENTIALS: "/secrets/gcp-sa-key.json"
      GOOGLE_CLOUD_PROJECT: "my-project-id"
    volumes:
      - ./gcp-sa-key.json:/secrets/gcp-sa-key.json:ro
```

!!! note "Keep the key out of version control"
    Add your service account key file to `.gitignore`.

#### Kubernetes

Option 1. A Secret with the service account key:

1. Create a secret from your service account JSON:

```bash
kubectl create secret generic gcp-credentials \
  --namespace=stategraph \
  --from-file=key.json=./gcp-sa-key.json
```

2. Mount the secret and set the environment variable:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stategraph
  namespace: stategraph
spec:
  template:
    spec:
      containers:
        - name: stategraph
          env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: "/secrets/gcp/key.json"
            - name: GOOGLE_CLOUD_PROJECT
              value: "my-project-id"
          volumeMounts:
            - name: gcp-credentials
              mountPath: /secrets/gcp
              readOnly: true
      volumes:
        - name: gcp-credentials
          secret:
            secretName: gcp-credentials
```

Option 2. Workload Identity, recommended for GKE:

1. Turn on Workload Identity on your GKE cluster.
2. Create a GCP service account with the required permissions.
3. Bind the Kubernetes service account to the GCP service account:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  stategraph-sa@PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:PROJECT_ID.svc.id.goog[stategraph/stategraph]"
```

4. Annotate the Kubernetes service account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: stategraph
  namespace: stategraph
  annotations:
    iam.gke.io/gcp-service-account: stategraph-sa@PROJECT_ID.iam.gserviceaccount.com
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stategraph
  namespace: stategraph
spec:
  template:
    spec:
      serviceAccountName: stategraph
      containers:
        - name: stategraph
          env:
            - name: GOOGLE_CLOUD_PROJECT
              value: "my-project-id"
```

Option 3. GCE metadata server. On GCE, or on GKE without Workload Identity, Stategraph uses the default service account. It needs the Cloud Asset Viewer permissions.

### Multi-cloud configuration

For AWS and GCP at the same time:

Docker Compose:

```yaml
services:
  server:
    image: ghcr.io/stategraph/stategraph-server:latest
    environment:
      # AWS
      AWS_DEFAULT_REGION: "us-east-1"
      # GCP
      GOOGLE_APPLICATION_CREDENTIALS: "/secrets/gcp-sa-key.json"
      GOOGLE_CLOUD_PROJECT: "my-project-id"
    volumes:
      - ~/.aws:/home/stategraph/.aws:ro
      - ./gcp-sa-key.json:/secrets/gcp-sa-key.json:ro
```

Kubernetes:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stategraph
  namespace: stategraph
spec:
  template:
    spec:
      serviceAccountName: stategraph  # With IRSA and/or Workload Identity
      containers:
        - name: stategraph
          env:
            # AWS
            - name: AWS_DEFAULT_REGION
              value: "us-east-1"
            # GCP
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: "/secrets/gcp/key.json"
            - name: GOOGLE_CLOUD_PROJECT
              value: "my-project-id"
          volumeMounts:
            - name: gcp-credentials
              mountPath: /secrets/gcp
              readOnly: true
      volumes:
        - name: gcp-credentials
          secret:
            secretName: gcp-credentials
```

## Next steps

- [Dashboards](/docs/infrastructure-as-a-database/query/dashboards): custom views of your inventory.
- [Query Language](/docs/infrastructure-as-a-database/query/query): query resources with SQL.
- [Environment Variables](/docs/admin/operations/environment-variables): full configuration reference.
