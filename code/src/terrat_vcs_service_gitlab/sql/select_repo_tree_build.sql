select rtb.sha
from repo_tree_builds as rtb
inner join gitlab_installations_map as gim
      on gim.core_id = rtb.installation
where gim.installation_id = $installation_id and rtb.sha = $sha
