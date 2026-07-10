select count(*) from gitlab_work_manifests as gwm
inner join gitlab_installation_repositories as gir
  on gwm.repository = gir.id
inner join gitlab_installations as gi
  on gir.installation_id = gi.id
where gi.id = $installation_id
      and gwm.created_at >= date_trunc('month', current_date)
      and gwm.created_at < date_trunc('month', current_date + interval '1 month')
      and gwm.run_type in ('autoplan', 'autoapply', 'plan', 'apply')
