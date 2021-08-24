alter table installation_config
      add column if not exists allow_draft_pr boolean not null default false,
      add column if not exists autoplan_file_list varchar(1024) not null default '**/*.tf',
      add column if not exists default_terraform_version varchar(64),
      add column if not exists enable_apply boolean not null default true,
      add column if not exists enable_apply_all boolean not null default true,
      add column if not exists enable_autoplan boolean not null default true,
      add column if not exists enable_diff_markdown_format boolean not null default true,
      add column if not exists enable_local_merge_dest_branch_before_plan boolean not null default false,
      add column if not exists enable_repo_locking boolean not null default true,
      add column if not exists require_approval boolean not null default false,
      add column if not exists require_mergeable boolean not null default true;


alter table installation_config
      alter column terragrunt set default false;

alter table installation_config
      rename column terragrunt to enable_terragrunt;


