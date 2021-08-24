alter table installation_config
      alter column autoplan_file_list set default '**/*.tf,**/*.tfvars,**/*.tfvars.json,**/terragrunt.hcl';
