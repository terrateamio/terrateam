---
title: Spacelift
description: Run Stategraph in Spacelift stacks with the custom workflow tool, and keep Spacelift triggers and approvals.
order: 5
---

A Spacelift stack can run the `stategraph` CLI in place of plain Terraform. Spacelift still triggers, approves, and audits runs. Plans and applies go through the CLI, and Stategraph holds the state, with scoped plans, per-resource conflict detection, and SQL over all your infrastructure. No resources move: you import the state.

## Before you begin

- A Stategraph server that your Spacelift workers can reach: [Stategraph Cloud](https://app.stategraph.cloud) or a [self-hosted](/docs/admin/self-hosting) deployment.
- A Stategraph API key and tenant. See [Setup](/docs/infrastructure-as-a-database/setup).
- Your Terraform repository attached to Spacelift through a VCS integration.

## Import your state

On a machine with your repository checked out, import the existing state once:

```bash
terraform state pull > terraform.tfstate
stategraph import tf --name mystack --tenant $STATEGRAPH_TENANT_ID --workspace default terraform.tfstate
```

- Commit the generated `stategraph.json`. The CLI finds the state through it.
- Note the state ID from `stategraph states list`. You set it on the stack later.
- If your configuration has a `backend` block, remove it. Stategraph is the backend now.

## Add the custom workflow

The Spacelift custom workflow tool replaces the built-in Terraform with your commands. Add `.spacelift/workflow.yml` at the repository root:

```yaml
init: /tmp/stategraph info
workspaceSelect: 'echo "workspace {{ .WorkspaceName }}"'
workspaceNew: 'echo "workspace {{ .WorkspaceName }}"'
plan: /tmp/stategraph plan --out "{{ .PlanFileName }}"
showPlan: /tmp/stategraph tf show --json "{{ .PlanFileName }}"
showState: sh -c '/tmp/stategraph states export -q --state "$STATEGRAPH_STATE_ID" 2>/dev/null | python3 ../.spacelift/showstate.py'
getOutputs: sh -c '/tmp/stategraph states export -q --state "$STATEGRAPH_STATE_ID" 2>/dev/null | python3 -c "import json,sys;print(json.dumps(json.load(sys.stdin).get(\"outputs\",{})))"'
apply: /tmp/stategraph apply "{{ .PlanFileName }}"
destroy: 'echo "destroy through Stategraph is not supported yet" && exit 1'
```

- `stategraph tf show --json` prints a Terraform-compatible JSON plan, so the Spacelift diff view, change counts, and plan policy inputs keep working.
- The state export carries `outputs` in `terraform output -json` shape for `getOutputs`. `jq .outputs` works too: both tools ship on the default runner.
- The CLI writes a plan file even with no changes, so idempotent runs finish cleanly.

`showState` feeds the Spacelift post-apply upload of managed resources. The upload accepts only the `terraform show -json` values representation, and rejects raw state JSON as "non-JSON output". Commit this transform as `.spacelift/showstate.py`. The `../` in `showState` assumes a project root one level below the repository root. Adjust it for your layout.

```python
# Transform a raw tfstate (stategraph states export) into the
# `terraform show -json` values representation Spacelift's post-apply
# managed-resources upload expects.
import json
import re
import sys

state = json.load(sys.stdin)
resources = []
for r in state.get("resources", []):
    for inst in r.get("instances", []):
        addr = f'{r["type"]}.{r["name"]}'
        if r.get("mode") == "data":
            addr = "data." + addr
        if r.get("module"):
            addr = f'{r["module"]}.{addr}'
        if inst.get("index_key") is not None:
            addr += f'[{json.dumps(inst["index_key"])}]'
        m = re.search(r'provider\["([^"]+)"\]', r.get("provider", ""))
        resources.append({
            "address": addr,
            "mode": r.get("mode", "managed"),
            "type": r["type"],
            "name": r["name"],
            "provider_name": m.group(1) if m else r.get("provider", ""),
            "schema_version": inst.get("schema_version", 0),
            "values": inst.get("attributes", {}),
        })
doc = {
    "format_version": "1.0",
    "terraform_version": state.get("terraform_version", "1.0.0"),
    "values": {"root_module": {"resources": resources}},
}
print(json.dumps(doc))
```

After every apply, the Spacelift Resources view lists the resources that Stategraph manages.

## Create the stack

Create the stack with the Terraform workflow tool set to `Custom`, and with:

- **Manage State** off. You can set this only at stack creation.
- The `nobackend` label, or Spacelift fails initialization looking for a local state backend.
- The project root on your Terraform directory, if that is not the repository root.

Add a `before_init` hook that installs the CLI and an OpenTofu binary on the worker, and the same hook as `before_apply`:

```bash
VERSION=$(curl -s https://api.github.com/repos/stategraph/releases/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4) && \
curl -fsSL https://github.com/stategraph/releases/releases/download/$VERSION/stategraph-$VERSION-linux-amd64.tar.gz -o /tmp/sg.tgz && \
tar xzf /tmp/sg.tgz -C /tmp stategraph && chmod +x /tmp/stategraph && \
curl -fsSL https://github.com/opentofu/opentofu/releases/download/v1.8.8/tofu_1.8.8_linux_amd64.tar.gz -o /tmp/tofu.tgz && \
mkdir -p /tmp/tofubin && tar xzf /tmp/tofu.tgz -C /tmp/tofubin tofu && chmod +x /tmp/tofubin/tofu
```

Or put both binaries in a custom runner image, and skip the hooks.

Set the stack environment variables:

| Variable | Value |
| --- | --- |
| `STATEGRAPH_API_BASE` | Your Stategraph server URL |
| `STATEGRAPH_API_KEY` | The API key (mark it write-only) |
| `STATEGRAPH_TENANT_ID` | Your tenant ID |
| `STATEGRAPH_STATE_ID` | The state ID from `stategraph states list` |
| `TF_CMD` | `/tmp/tofubin/tofu`, the OpenTofu binary from the hook, which the CLI calls to plan |

## Run it

Trigger a run. Spacelift shows the diff from the JSON plan and holds at Unconfirmed. When you confirm, the run applies through `stategraph apply`. The Spacelift run view and the Stategraph transaction log show the plan, the apply, and who confirmed it.

Runs that touch different resources do not wait for each other's state lock. Stategraph detects conflicts per resource at commit.

## Pull request flow

Proposed runs work unchanged:

1. A pull request against the tracked branch triggers a proposed run. The plan lands on the pull request as a commit check (`spacelift/<stack>`), with the change counts, a resource-level diff from the Stategraph plan, and a link to the full plan output.
2. Merging triggers a tracked run, which plans again and holds at Unconfirmed, as in [Run it](#run-it), or applies at once with autodeploy on.
3. After you confirm, `getOutputs` feeds the stack outputs to the Spacelift outputs view.

By default, Spacelift posts checks, not pull request comments. For a plan summary as a comment, add a notification policy.

## Limitations

- The CLI does not support destroy runs yet. Run destroys locally and re-import, or keep destroy plans out of Spacelift.
- Spacelift scheduled drift detection is a scheduled proposed run of the workflow's `plan` command, which this setup already serves.
- A Spacelift plan tier must include drift detection. Other tiers refuse the schedule ("Drift detection and advanced scheduling are not supported by your plan").
- Stategraph Orchestration has its own scheduled [drift detection](/docs/orchestration/governance/drift-detection).

## Next Steps

- [Transactions](/docs/infrastructure-as-a-database/transactions): what a plan and apply commit.
- [Multi-state transactions](/docs/infrastructure-as-a-database/multi-state): atomic changes across states.
- [Self-hosting](/docs/admin/self-hosting): the server that your workers talk to.
