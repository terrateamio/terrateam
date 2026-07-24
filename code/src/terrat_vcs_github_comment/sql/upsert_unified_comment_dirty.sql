insert into github_unified_comments (repository, pull_number, dirty)
select
    gwm.repository,
    gwm.pull_number,
    1
from github_work_manifests as gwm
where gwm.id = $work_manifest and gwm.pull_number is not null
on conflict (repository, pull_number)
do update set dirty = github_unified_comments.dirty + 1
