update work_manifests set
  completed_at = now(),
  state = 'aborted'
from github_work_manifests as wm
inner join github_pull_request_latest_unlocks as pru
  on pru.repository = wm.repository and pru.pull_number = wm.pull_number
where work_manifests.id = wm.id and  wm.state in ('running', 'queued') and wm.created_at < pru.unlocked_at;

update work_manifests set
  completed_at = now(),
  state = 'aborted'
from github_work_manifests as wm
inner join github_drift_latest_unlocks as du
  on du.repository = wm.repository
where work_manifests.id = wm.id and wm.state in ('running', 'queued') and wm.run_kind = 'drift' and wm.created_at < du.unlocked_at;
