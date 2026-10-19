---
title: Plan file storage
description: Choose where Stategraph Orchestration keeps the plan file between plan and apply. Use the server, an S3 bucket, custom commands, or no storage.
order: 6
---


Stategraph Orchestration applies the exact plan file that was reviewed in the pull request, so it stores the file between the plan run and the apply run. The `storage` key in `.stategraph/config.yml` sets where: the Orchestration server, an S3 bucket, your own commands, or nowhere. A workflow can override the top-level `storage` for its directories.

Plan files can contain sensitive values from your configuration and state. Restrict access to the store.

## Configuring plan file storage

```yaml
storage:
  plans:
    method: s3
    bucket: my-terraform-plans
    region: us-east-1
```

This example stores plan files in the AWS S3 bucket that `bucket` and `region` set.

### Storage methods

The `method` key selects one of:

- `terrateam` (default): the Orchestration server keeps plan files in its database. It takes no other keys.
- `s3`: an S3-compatible bucket keeps the plan files. `bucket` and `region` are required.
- `cmd`: commands that you supply store and fetch the plan files. `store` and `fetch` are required. `delete` is optional.
- `none`: plan files are not kept after the plan run. The apply fails, unless the same storage block also sets `unsafe_apply_without_plan: true`. Then the apply runs a new non-interactive apply, not the reviewed plan.

The template variables `$dir`, `$workspace`, `$date`, `$time`, and `$token` build a unique path for each plan. See the [storage reference](/docs/reference/orchestration/configuration/storage) for the full list.

### S3 storage

The credentials on the runner need permission to put, get, and delete objects in the bucket.

| Key | Description |
| --- | --- |
| `bucket` | Bucket name. Required. |
| `region` | Region of the bucket. Required. |
| `path` | Object path in the bucket. Defaults to `terrateam/plans/$dir/$workspace/$date-$time-$token`. |
| `access_key_id` | Access key ID. Optional. Default: the AWS credential chain of the runner. |
| `secret_access_key` | Secret access key. Optional. Default: the AWS credential chain of the runner. |
| `delete_used_plans` | Delete the stored plan file when the apply run fetches it. Default `true`. |
| `store_extra_args`, `fetch_extra_args`, `delete_extra_args` | Extra arguments for `aws s3 cp` when storing and fetching, and for `aws s3 rm` when deleting. |

### Custom command storage

The commands need access to the storage system and its credentials.

| Key | Description |
| --- | --- |
| `store` | The command that stores the plan file. `$plan_path` is the path of the file to store. |
| `fetch` | The command that fetches the plan file. `$plan_dst_path` is the path that the command must write the file to. Orchestration reads the file from that path, not from standard output. |
| `delete` | Optional. The command that deletes the stored plan file when the apply run fetches it. `$plan_dst_path` is not substituted in it. |

Google Cloud Storage with `gsutil`:

```yaml
storage:
  plans:
    method: cmd
    store: ["gsutil", "cp", "$plan_path", "gs://my-terraform-plans/$dir/$workspace/$date-$time-$token"]
    fetch: ["gsutil", "cp", "gs://my-terraform-plans/$dir/$workspace/$date-$time-$token", "$plan_dst_path"]
    delete: ["gsutil", "rm", "gs://my-terraform-plans/$dir/$workspace/$date-$time-$token"]
```

An HTTP store with `curl`:

```yaml
storage:
  plans:
    method: cmd
    store: ["curl", "-X", "PUT", "--data-binary", "@$plan_path", "https://plan-storage.example.com/$dir/$workspace/$date-$time-$token"]
    fetch: ["curl", "-X", "GET", "https://plan-storage.example.com/$dir/$workspace/$date-$time-$token", "-o", "$plan_dst_path"]
    delete: ["curl", "-X", "DELETE", "https://plan-storage.example.com/$dir/$workspace/$date-$time-$token"]
```

### Disabling plan storage for one workflow

```yaml
storage:
  plans:
    method: s3
    bucket: my-terraform-plans
    region: us-east-1

workflows:
  - tag_query: "engine:terragrunt"
    engine:
      name: terragrunt
    storage:
      plans:
        method: none
        unsafe_apply_without_plan: true
```

Use `method: none` for a workflow whose saved plan would hold values that the apply must calculate again. The workflow then loses the reviewed-plan guarantee, because the apply evaluates the configuration again.

### Using environment variables

`bucket` and `region` accept environment variables, so a workflow can choose the bucket:

```yaml
workflows:
  - tag_query: "dir:production"
    plan:
      - type: env
        name: MY_PLAN_BUCKET
        cmd: ['echo', 'production-bucket-name']
      - type: init
      - type: plan
    apply:
      - type: env
        name: MY_PLAN_BUCKET
        cmd: ['echo', 'production-bucket-name']
      - type: init
      - type: apply
  - tag_query: ""
    plan:
      - type: env
        name: MY_PLAN_BUCKET
        cmd: ['echo', 'non-production-bucket-name']
      - type: init
      - type: plan
    apply:
      - type: env
        name: MY_PLAN_BUCKET
        cmd: ['echo', 'non-production-bucket-name']
      - type: init
      - type: apply
storage:
  plans:
    method: s3
    bucket: $MY_PLAN_BUCKET
    region: us-east-1
```

Also set each variable that the storage block uses in a catch-all workflow (`tag_query: ""`), so that each directory gets a value.

## How plan files are used

1. Orchestration plans a pull request that changes Terraform code, and stores the plan file, unless the matching workflow uses `method: none`.
2. After review and approval, someone comments `stategraph apply`.
3. Orchestration fetches the stored plan file and applies it. With `method: none`, the apply runs without a stored plan.
4. If storage is set to delete used plans, Orchestration deletes the stored file after it fetches it.

## Best practices

- Use one naming convention for stored plan files, so that they are easy to find.
- Set a retention policy on the store, so that old plan files do not pile up.

## Next steps

- [Storage reference](/docs/reference/orchestration/configuration/storage): every key, type, and default.
- [Apply after merge](/docs/orchestration/workflows/apply-after-merge): how stored plans reach the apply run.
