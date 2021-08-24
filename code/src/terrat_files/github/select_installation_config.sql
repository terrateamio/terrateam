select
        allow_draft_pr,
        auto_merge_after_apply,
        autoplan_file_list,
        default_terraform_version,
        enable_apply,
        enable_apply_all,
        enable_autoplan,
        enable_diff_markdown_format,
        enable_local_merge_dest_branch_before_plan,
        enable_repo_locking,
        enable_terragrunt,
        require_approval,
        require_mergeable,
        to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        updated_by
from installation_config
inner join github_user_installations on
      installation_config.installation_id = github_user_installations.installation_id
where installation_config.installation_id = $installation_id
      and ($user_id is null or github_user_installations.user_id = $user_id)
