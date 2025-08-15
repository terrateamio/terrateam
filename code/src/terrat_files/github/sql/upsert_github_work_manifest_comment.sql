with wm AS (
    select
        gwm.pull_number,
        gwm.repository,
        gwm.run_type,
        case 
          when gwm.run_type in ('autoplan', 'plan') then 'plan'
          when gwm.run_type in ('autoapply', 'apply') then 'apply'
          else gwm.run_type
        end as unified_run_type
    from github_work_manifests gwm
    where id = $work_manifest
),
insert_comment as (
  insert into github_work_manifest_comments(comment_id, work_manifest, repository, pull_number, dir, workspace, unified_run_type)
  select
      $comment_id, 
      $work_manifest, 
      wm.repository,
      wm.pull_number,
      $dir,
      $workspace,
      wm.unified_run_type
  from wm
  on conflict (repository, pull_number, dir, workspace, unified_run_type)
  do update 
      set comment_id = excluded.comment_id,
          created_at = current_timestamp,
          work_manifest = excluded.work_manifest
  returning comment_id
)
select comment_id
from insert_comment
