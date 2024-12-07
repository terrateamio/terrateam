alter table github_terraform_plans
      add column has_changes boolean not null default true;
