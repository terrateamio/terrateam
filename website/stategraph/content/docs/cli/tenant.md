---
title: Tenant Commands
description: CLI commands for tenant gap analysis: find cloud resources that Terraform does not manage, check the setup, and generate import blocks.
order: 5
---


The `stategraph tenant` commands run gap analysis for a tenant: they find cloud resources that Terraform does not manage, and generate `import` blocks for them.

## Commands

| Command | Description |
|---------|-------------|
| `stategraph tenant gaps analyze` | Run gap analysis |
| `stategraph tenant gaps config` | Show the gap analysis configuration |
| `stategraph tenant gaps import` | Generate Terraform `import` blocks for unmanaged resources |

Common options:

- All commands require `--tenant` (a UUID, or set `STATEGRAPH_TENANT_ID`).
- `--provider` sets the cloud provider, for example `aws`. `analyze` and `config` require it. For `import`, the default is `aws`.

## stategraph tenant gaps analyze

`stategraph gaps` is an alias.

```bash
stategraph tenant gaps analyze --tenant <tenant-id> --provider <provider> [options]
```

### Options

| Option | Required | Description |
|--------|----------|-------------|
| `--source` | No | Data source: `cache` (default) or `no-cache` |
| `--format` | No | Output format: `table` (default), `json`, or `simple` |

### Example

```bash
stategraph tenant gaps analyze \
  --tenant 550e8400-e29b-41d4-a716-446655440000 \
  --provider aws \
  --format json
```

Gap analysis runs in the background. The first call for a provider starts a scan and returns `{"status": "running", "started_at": "<timestamp>"}`, or a `status`, `started_at`, `error` row in table format. Run the command again when the scan finishes. Later calls read from the cache. For the full flow, see [Gap analysis](/docs/infrastructure-as-a-database/query/gap-analysis).

The default table has the columns `resource_type`, `service`, `id`, `region`, and `arn`, then a summary line of managed, unmanaged, and total cloud resource counts.

Output (with `--format json`):

```json
{
  "summary": {
    "total_aws_resources": 1500,
    "total_cloud_resources": 1500,
    "managed_by_stategraph": 1200,
    "unmanaged": 300,
    "phantom_filtered": 8
  },
  "unmanaged_resources": [
    {
      "id": "arn:aws:s3:::orphaned-bucket",
      "arn": "arn:aws:s3:::orphaned-bucket",
      "provider": "aws",
      "service": "s3",
      "resource_type": "s3:bucket",
      "region": "us-east-1",
      "owning_account_id": "123456789012"
    }
  ],
  "fetched_at": 1705312800
}
```

### Force Fresh Scan

```bash
stategraph tenant gaps analyze \
  --tenant 550e8400-e29b-41d4-a716-446655440000 \
  --provider aws \
  --source no-cache
```

## stategraph tenant gaps config

Shows whether the provider is ready for gap analysis and for Terraform import.

```bash
stategraph tenant gaps config --tenant <tenant-id> --provider <provider>
```

### Example

```bash
stategraph tenant gaps config \
  --tenant 550e8400-e29b-41d4-a716-446655440000 \
  --provider aws
```

Output (JSON):

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

## stategraph tenant gaps import

`<resources-file>` is a JSON file with an array of the resources to import: the `unmanaged_resources` from `gaps analyze`. The command returns ready-to-use `import` blocks and generated resource HCL.

```bash
stategraph tenant gaps import --tenant <tenant-id> [--provider <provider>] <resources-file>
```

### Example

1. Save the unmanaged resources to a file:

```bash
stategraph tenant gaps analyze --tenant $TENANT_ID --provider aws --format json | \
  jq '.unmanaged_resources' > unmanaged.json
```

2. Generate the import blocks and configuration:

```bash
stategraph tenant gaps import --tenant $TENANT_ID unmanaged.json
```

Output (JSON):

```json
{
  "import_blocks": "import {\n  provider = aws.us_east_1\n  to       = aws_s3_bucket.imported_orphaned_bucket\n  id       = \"orphaned-bucket\"\n}",
  "provider_hcl": "terraform {\n  required_providers {\n    aws = {\n      source  = \"hashicorp/aws\"\n      version = \"~> 5.0\"\n    }\n  }\n}\n",
  "generated_hcl": "resource \"aws_s3_bucket\" \"imported_orphaned_bucket\" {\n  bucket = \"orphaned-bucket\"\n  # ... generated attributes\n}\n",
  "supported_count": 1,
  "unsupported_count": 0,
  "unsupported_resources": []
}
```

## Scripting Examples

### Weekly Gap Analysis Report

```bash
#!/bin/bash
TENANT_ID="550e8400-e29b-41d4-a716-446655440000"

echo "Gap Analysis Report - $(date)"
echo "================================"
echo ""

result=$(stategraph tenant gaps analyze --tenant $TENANT_ID --provider aws --source no-cache --format json)

total=$(echo $result | jq '.summary.total_aws_resources')
managed=$(echo $result | jq '.summary.managed_by_stategraph')
unmanaged=$(echo $result | jq '.summary.unmanaged')

echo "Total AWS resources: $total"
echo "Managed by Terraform: $managed"
echo "Unmanaged: $unmanaged"
echo ""
echo "Coverage: $(echo "scale=2; $managed * 100 / $total" | bc)%"
echo ""
echo "Top unmanaged resource types:"
echo $result | jq -r '.unmanaged_resources | group_by(.service) | map({service: .[0].service, count: length}) | sort_by(-.count) | .[:5][] | "  \(.service): \(.count)"'
```

### Find and Import S3 Buckets

```bash
#!/bin/bash
TENANT_ID="550e8400-e29b-41d4-a716-446655440000"

# Get unmanaged S3 buckets
stategraph tenant gaps analyze --tenant $TENANT_ID --provider aws --format json | \
  jq '[.unmanaged_resources[] | select(.service == "s3")]' > s3_unmanaged.json

# Generate import blocks
stategraph tenant gaps import --tenant $TENANT_ID s3_unmanaged.json | \
  jq -r '.import_blocks' > import.tf

echo "Generated import.tf with $(jq length s3_unmanaged.json) S3 bucket imports"
```

### Monitor Gap Trend

```bash
#!/bin/bash
TENANT_ID="550e8400-e29b-41d4-a716-446655440000"
LOG_FILE="gap_history.csv"

# Add header if file doesn't exist
if [ ! -f $LOG_FILE ]; then
  echo "date,total,managed,unmanaged,coverage" > $LOG_FILE
fi

result=$(stategraph tenant gaps analyze --tenant $TENANT_ID --provider aws --format json)

total=$(echo $result | jq '.summary.total_aws_resources')
managed=$(echo $result | jq '.summary.managed_by_stategraph')
unmanaged=$(echo $result | jq '.summary.unmanaged')
coverage=$(echo "scale=4; $managed / $total" | bc)

echo "$(date -I),$total,$managed,$unmanaged,$coverage" >> $LOG_FILE
```

## Next Steps

- [Gap analysis](/docs/infrastructure-as-a-database/query/gap-analysis): the full gap analysis documentation.
- [States](/docs/cli/states): state management commands.
- [Troubleshooting](/docs/reference/troubleshooting): common issues.
