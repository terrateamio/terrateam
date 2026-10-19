---
title: Modules
description: Trigger plans in the directories that depend on a Terraform module, discover dependencies automatically, and clone modules from private repositories.
order: 2
---


When a Terraform module changes, Stategraph Orchestration plans and applies the directories that use it, and it clones modules from public and private Git repositories during plan and apply. You declare the dependencies with `when_modified`, or the indexer discovers them for you. A module packages infrastructure that you reuse across root modules.

## Triggering on module updates

To plan each directory that uses a module when the module changes, set the [when_modified](/docs/reference/orchestration/configuration/when-modified) key in `.stategraph/config.yml`. This configuration makes the `iam` directory depend on the `modules` directory:

```yaml
dirs:
  modules:
    when_modified:
      file_patterns: []
  iam:
    when_modified:
      file_patterns: ["iam/*.tf", "iam/*.tfvars", "modules/*.tf"]
```

- The `modules` directory has an empty `file_patterns` list, so a change in it never triggers an operation for the directory itself.
- The `iam` directory plans when a file that matches `iam/*.tf`, `iam/*.tfvars`, or `modules/*.tf` changes. A change to a Terraform file under `modules` thus shows in the plan of `iam`.

## Automatic module discovery

The [indexer](/docs/reference/orchestration/configuration/indexer) makes a map of your repository: the Terraform modules, the directories that reference them, and the symbolic links. From that map, it decides which directories run during plan and apply, so you need no `file_patterns` for module dependencies:

- A module directory does not run when it changes.
- A directory that references a module runs when the module changes.

Enable the indexer in `.stategraph/config.yml`:

```yaml
indexer:
  enabled: true
```

The indexer runs as its own job before Orchestration evaluates your plan. For when that cost is worth it, see [Performance](/docs/orchestration/workflows/performance).

### Example

In this repository, `prod/network` references the `vpc` module:

```text
modules/
  vpc/
    main.tf
prod/
  network/
    main.tf
```

With the indexer enabled:

```yaml
indexer:
  enabled: true
```

1. Open a pull request that changes `modules/vpc`. The indexer finds that `prod/network` depends on the module.
2. Orchestration does not run `modules/vpc` directly, and it triggers a plan for `prod/network`.
3. Review the plan with your team.
4. Apply the change to `prod/network` by commenting `stategraph apply`.

## Using modules from a separate repository

### Public repositories

Reference a public GitHub repository in your Terraform code:

```hcl
module "consul" {
  source = "github.com/opentofu/example"
}
```

Terraform clones `github.com` sources during plan and apply. For a public GitLab project, use a generic Git source such as `git::https://gitlab.com/GROUP/TERRAFORM-MODULES.git`.

### Private repositories

To clone a private modules repository, the runner needs an SSH key:

- Store the private key as a GitHub Actions secret or a GitLab CI/CD variable named `TERRATEAM_SSH_KEY`. The runner finds it and configures SSH access before plan and apply.
- For more keys, add secrets or variables with the `TERRATEAM_SSH_KEY_` prefix, for example `TERRATEAM_SSH_KEY_FOO` and `TERRATEAM_SSH_KEY_BAR`.
- The runner adds the host keys of `github.com` to its known hosts file.
- For all other hosts, GitLab too, add a pre-hook that runs `ssh-keyscan-pre-hook`. This script on the runner wraps `ssh-keyscan` and adds the keys of the host to the known hosts file, so that the clone succeeds.

#### GitHub

1. Install the GitHub App that you use for Orchestration on the private modules repository too. This gives the permissions to clone it.
2. Generate a new SSH key pair:

```bash
ssh-keygen -t ed25519 -C "Stategraph SSH key" -N "" -f ~/.ssh/stategraph-ssh-key
```

3. Add the public key to the private modules repository as a deploy key:

```bash
gh repo deploy-key --repo "OWNER/TERRAFORM-MODULES-REPO" add ~/.ssh/stategraph-ssh-key.pub
```

4. Add the private key to your main Terraform repository as a GitHub Actions secret named `TERRATEAM_SSH_KEY`:

```bash
gh secret --repo "OWNER/TERRAFORM-REPO" set TERRATEAM_SSH_KEY < ~/.ssh/stategraph-ssh-key
```

5. Reference the private repository with its SSH URL:

```hcl
module "example_module" {
  source = "git::ssh://git@github.com/OWNER/TERRAFORM-MODULES-REPO.git"
}
```

#### GitLab

1. Generate a new SSH key pair:

```bash
ssh-keygen -t ed25519 -C "Stategraph SSH key" -N "" -f ~/.ssh/stategraph-ssh-key
```

2. In the private modules project, open **Settings**, then **Repository**, then **Deploy keys**, and add the contents of `~/.ssh/stategraph-ssh-key.pub` as a deploy key.
3. In your main Terraform project, open **Settings**, then **CI/CD**, then **Variables**.
4. Add a variable with the key `TERRATEAM_SSH_KEY` and the contents of `~/.ssh/stategraph-ssh-key` as its value. Use the **Variable** type, not **File**: the runner reads the key from the value of the variable.
5. Leave **Protect variable** cleared, as [Secrets and variables](/docs/orchestration/configuration/variables) describes.
6. Reference the private project with its SSH URL:

```hcl
module "example_module" {
  source = "git::ssh://git@gitlab.com/GROUP/TERRAFORM-MODULES.git"
}
```

7. To scan the SSH keys of the GitLab host before plan and apply, add this to `.stategraph/config.yml`:

```yaml
hooks:
  plan:
    pre:
      - type: run
        cmd: ['ssh-keyscan-pre-hook', 'gitlab.com']
  apply:
    pre:
      - type: run
        cmd: ['ssh-keyscan-pre-hook', 'gitlab.com']
```

On self-managed GitLab, use your instance's host name in the module source and in the hooks.

### Other Git hosts

Modules on other Git servers work the same way.

1. Generate a new SSH key pair:

```bash
ssh-keygen -t ed25519 -C "Stategraph SSH key" -N "" -f ~/.ssh/stategraph-ssh-key
```

2. Add the public key to your Git hosting provider as an authorized key for the modules repository.
3. Add the private key to your main Terraform repository as `TERRATEAM_SSH_KEY`, in a GitHub Actions secret or a GitLab CI/CD variable. With the GitHub CLI:

```bash
gh secret --repo "OWNER/TERRAFORM-REPO" set TERRATEAM_SSH_KEY < ~/.ssh/stategraph-ssh-key
```

4. Reference the repository with its SSH URL:

```hcl
module "example_module" {
  source = "git::ssh://username@example.com/TERRAFORM-MODULES-REPO.git"
}
```

5. To scan the SSH keys of the host before plan and apply, add this to `.stategraph/config.yml`:

```yaml
hooks:
  plan:
    pre:
      - type: run
        cmd: ['ssh-keyscan-pre-hook', 'example.com']
  apply:
    pre:
      - type: run
        cmd: ['ssh-keyscan-pre-hook', 'example.com']
```

## Best practices

- Keep each module on one piece of functionality.
- Version your modules, and pin the version in your Terraform code, so that runs are reproducible.
- If a modules repository never needs plans or applies, disable Orchestration there with `enabled: false` in `.stategraph/config.yml` on its default branch. See [enabled](/docs/reference/orchestration/configuration/enabled).
- Rotate the SSH deploy keys of private module repositories regularly.
- Keep modules and the root modules that use them in separate directories.

## Next Steps

- [when_modified](/docs/reference/orchestration/configuration/when-modified): file patterns and dependency rules.
- [indexer](/docs/reference/orchestration/configuration/indexer): automatic module discovery reference.
- [Performance](/docs/orchestration/workflows/performance): when the indexer pays for itself.
