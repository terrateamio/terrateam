select
  token,
  approver
from gate_approvals as gga
inner join github_pull_requests as gpr
  on (gpr.repository = gga.repository and gpr.pull_number = gga.pull_number
      and (gpr.sha = gga.sha or gpr.merged_sha = gga.sha))
where gga.repository = $repository and gga.pull_number = $pull_number and gga.approver <> gpr.username
