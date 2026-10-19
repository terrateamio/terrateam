---
title: CDKTF
description: Run CDKTF stacks through Stategraph Orchestration. Enable the cdktf engine per directory, plan a stack by tag, and read runner environment variables.
order: 5
---

Stategraph Orchestration plans and applies CDKTF stacks from pull requests, with the same approvals as plain Terraform. CDKTF (Cloud Development Kit for Terraform) defines infrastructure in TypeScript, Python, Java, C#, or Go.

## Enable CDKTF

The `engine` key sets the tool that Orchestration runs: Terraform, OpenTofu, the `stategraph` CLI, Terragrunt, Pulumi, CDKTF, or a custom command. Set the `cdktf` engine for specific directories or workflows in `.stategraph/config.yml`. This example sets it for the `prod` directory:

```yaml
workflows:
  - tag_query: cdktf-code
    engine:
      name: cdktf
dirs:
  prod:
    tags: [cdktf-code]
    when_modified:
      file_patterns: ['${DIR}/*.ts']
    stacks:
      'cdktf-stack1':
        tags: []
      'cdktf-stack2':
        tags: []
```

- The `workflows` entry runs the `cdktf` engine for each directory with the `cdktf-code` tag.
- The `prod` directory has the `cdktf-code` tag. A change to a `*.ts` file in it starts a run.
- `prod` defines two stacks, `cdktf-stack1` and `cdktf-stack2`. Each stack gets the tag `stack:<name>`, as each workspace gets `workspace:<name>`.

## Plan and apply

The standard pull request commands plan and apply your stacks. To plan each directory that has a stack named `cdktf-stack1`, comment on the pull request:

```
stategraph plan stack:cdktf-stack1
```

For each run, Orchestration runs `cdktf get` and `cdktf synth`. `synth` converts your app, with its stacks, providers, and resources, into Terraform configuration in JSON. Terraform then plans and applies the configuration of the stack. To use OpenTofu in place of Terraform, set `tf_cmd: tofu` on the engine.

## Environment variables

Your CDKTF code can read the environment variables that the runner sets for the run:

- `TERRATEAM_DIR`: the directory of the run
- `TERRATEAM_WORKSPACE`: the workspace of the run
- `TERRATEAM_PLAN_FILE`: the path to the plan file
- `TERRATEAM_ROOT`: the absolute path to the root of the repository checkout

For the full list, see [Environment variables](/docs/orchestration/configuration/environment-variables). This TypeScript stack reads two of them:

```typescript
import { Construct } from "constructs";
import { App, TerraformStack } from "cdktf";
import * as Null from './.gen/providers/null';
class MyStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);
    new Null.provider.NullProvider(this, 'test-provider');
    new Null.resource.Resource(this, 'test', {
      triggers: {
        dir: process.env.TERRATEAM_DIR,
        workspace: process.env.TERRATEAM_WORKSPACE
      }
    });
  }
}
const app = new App();
new MyStack(app, "cdktf-stack1");
app.synth();
```

The two values become the `triggers` of a `null_resource`, so the resource depends on the directory and workspace of the run.

## Next Steps

- [engine reference](/docs/reference/orchestration/configuration/engine): the `cdktf` engine keys, including `tf_cmd` and `tf_version`
- [dirs reference](/docs/reference/orchestration/configuration/dirs): the `stacks` key and directory configuration
- [Tags and tag queries](/docs/orchestration/workflows/advanced/tag-system): targeting stacks and directories in commands
- [CDK for Terraform documentation](https://developer.hashicorp.com/terraform/cdktf) and the [hashicorp/terraform-cdk repository](https://github.com/hashicorp/terraform-cdk)
