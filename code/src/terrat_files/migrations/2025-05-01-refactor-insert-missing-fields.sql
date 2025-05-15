update change_dirspaces as cd
set repo = grm.core_id
from github_repositories_map as grm
where grm.repository_id = cd.repository;

update code_indexes as ci
set installation = gim.core_id
from github_installations_map as gim
where gim.installation_id = ci.installation_id;

update drift_schedules as ds
set repo = grm.core_id
from github_repositories_map as grm
where grm.repository_id = ds.repository;

update drift_unlocks as du
set repo = grm.core_id
from github_repositories_map as grm
where grm.repository_id = du.repository;

update gate_approvals as ga
set pull_request = gprm.core_id
from github_pull_requests_map as gprm
where gprm.repository_id = ga.repository and gprm.pull_number = ga.pull_number;

update gates as g
set pull_request = gprm.core_id
from github_pull_requests_map as gprm
where gprm.repository_id = g.repository and gprm.pull_number = g.pull_number;

update pull_request_unlocks as gpru
set pull_request = gprm.core_id
from github_pull_requests_map as gprm
where gprm.repository_id = gpru.repository and gprm.pull_number = gpru.pull_number;

update repo_configs as rc
set installation = gim.core_id
from github_installations_map as gim
where gim.installation_id = rc.installation_id;

update repo_trees as rt
set installation = gim.core_id
from github_installations_map as gim
where gim.installation_id = rt.installation_id;

update work_manifests as wm
set pull_request = gprm.core_id
from github_pull_requests_map as gprm
where gprm.repository_id = wm.repository and gprm.pull_number = wm.pull_number;

update work_manifests as wm
set repo = grm.core_id
from github_repositories_map as grm
where grm.repository_id = wm.repository;

alter table change_dirspaces
      alter column repo set not null,
      add constraint change_dirspaces_fut_pkey unique (repo, base_sha, sha, path, workspace);

alter table code_indexes
      alter column installation set not null,
      add constraint code_indexes_fut_pkey unique (installation, sha);

alter table drift_schedules
      alter column repo set not null,
      add constraint drift_schedules_fut_pkey unique (repo, name);

alter table drift_unlocks
      alter column repo set not null,
      add constraint drift_unlocks_fut_pkey unique (repo, unlocked_at);

alter table gate_approvals
      alter column pull_request set not null,
      add constraint gate_approvals_fut_pkey unique (pull_request, sha, token, approver);

alter table gates
      alter column pull_request set not null,
      add constraint gates_fut_pkey unique (pull_request, sha, dir, workspace, token);

alter table pull_request_unlocks
      alter column pull_request set not null,
      add constraint pull_request_unlocks_fut_pkey unique (pull_request, unlocked_at);

alter table repo_configs
      alter column installation set not null,
      add constraint repo_configs_fut_pkey unique (installation, sha);

alter table repo_trees
      alter column installation set not null,
      add constraint repo_trees_fut_pkey unique (installation, sha, path);

alter table work_manifests
      alter column repo set not null;
