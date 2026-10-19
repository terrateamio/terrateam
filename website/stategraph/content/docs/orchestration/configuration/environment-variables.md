---
title: Environment Variables
description: Use the environment variables that the runner sets in workflows and hooks, and define your own variables with env steps.
order: 4
---


The runner sets environment variables that describe the current operation, and you can add your own with `env` steps in workflows and hooks. For the variables that configure a self-hosted Stategraph server, see [Environment variables](/docs/admin/operations/environment-variables).

## Built-in environment variables

The runner sets the same built-in variables on GitHub Actions and GitLab CI.

### Workflow environment variables

| Name | Description |
|------|-------------|
| `TERRATEAM_PLAN_FILE` | The path to the generated Terraform plan file. |
| `TERRATEAM_DIR` | The working directory, relative to the root of the repository. |
| `TERRATEAM_WORKSPACE` | The Terraform workspace of the run. |
| `TERRATEAM_ROOT` | The absolute path to the root of the checked-out repository. |

### Post-hook environment variables

| Name | Description |
|------|-------------|
| `TERRATEAM_RESULTS_FILE` | The path to a JSON file with the results of each dirspace that ran. |

An example results file:

```json
{
    "dirspaces": [
        {
            "path": "database",
            "workspace": "default",
            "success": true,
            "outputs": [
                {
                    "workflow_step": {
                        "type": "run",
                        "cmd": [
                            "tofu",
                            "init"
                        ],
                        "exit_code": 0
                    },
                    "success": true,
                    "outputs": {
                        "output_key": "init",
                        "text": "Initializing the backend...\n\nInitializing provider plugins...\n- Finding latest version of hashicorp/null...\n- Installing hashicorp/null v3.2.2...\n\nOpenTofu has been successfully initialized!\n"
                    }
                },
                {
                    "workflow_step": {
                        "type": "plan"
                    },
                    "success": true,
                    "outputs": {
                        "plan": "\nOpenTofu will perform the following actions:\n\n  # null_resource.foo will be created\n  + resource \"null_resource\" \"foo\" {\n      + id = (known after apply)\n    }\n\nPlan: 1 to add, 0 to change, 0 to destroy.\n",
                        "plan_text": "\nOpenTofu will perform the following actions:\n\n  # null_resource.foo will be created\n  + resource \"null_resource\" \"foo\" {\n      + id = (known after apply)\n    }\n\nPlan: 1 to add, 0 to change, 0 to destroy.\n",
                        "has_changes": true
                    }
                }
            ]
        }
    ],
    "overall": {
        "success": true
    }
}
```

### CI platform environment variables

The default environment variables of your CI platform are also available. See the [GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables) and [GitLab CI/CD](https://docs.gitlab.com/ee/ci/variables/predefined_variables/) lists.

## Custom environment variables

Define your own variables in [workflows](/docs/reference/orchestration/configuration/workflows) and [hooks](/docs/reference/orchestration/configuration/hooks), to pass data between steps, set options, or compute values from the run context.

### In workflows

Use the `env` step type. The output of the command becomes the value:

```yaml
workflows:
  - tag_query: ""
    plan:
      - type: env
        name: MY_CUSTOM_VAR
        cmd: ['echo', 'Hello, World!']
      - type: run
        cmd: ['echo', 'The value of MY_CUSTOM_VAR is: $MY_CUSTOM_VAR']
      - type: init
      - type: plan
```

The `env` step sets `MY_CUSTOM_VAR` to `Hello, World!`, and the next `run` step reads it.

### In hooks

Use the `env` hook type the same way:

```yaml
hooks:
  plan:
    pre:
      - type: env
        name: MY_HOOK_VAR
        cmd: ['echo', 'Hello from the pre-plan hook!']
    post:
      - type: run
        cmd: ['echo', 'The value of MY_HOOK_VAR is: $MY_HOOK_VAR']
```

The pre-plan `env` hook sets `MY_HOOK_VAR`, and the post-plan `run` hook reads it.

### Using the variables

Reference a variable as `$` and its name. The runner expands the value when the step runs:

```yaml
workflows:
  - tag_query: ""
    plan:
      - type: run
        cmd: ['echo', 'The value of MY_CUSTOM_VAR is: $MY_CUSTOM_VAR']
      - type: init
      - type: plan
```

## Best practices

- Give custom variables descriptive names that cannot collide with the built-in `TERRATEAM_*` variables or system variables.
- Keep secrets out of `env` steps in the config file. Use [GitHub secrets or GitLab CI/CD variables](/docs/orchestration/configuration/variables), or a secrets manager.
- Make scripts handle a missing or empty variable, so that a step fails with a clear message and not with an unexpected result.

## Next Steps

- [Secrets and variables](/docs/orchestration/configuration/variables): CI secrets, `TF_VAR_` handling, and `.tfvars` files.
- [hooks](/docs/reference/orchestration/configuration/hooks): the `env` hook and its `sensitive` flag.
