select
  gi.id,
  gi.login,
  gi.account_status,
  to_char(gi.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
  to_char(gi.trial_ends_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as trial_ends_at,
  tiers.name,
  tiers.features
from github_user_installations2 as gui
inner join github_installations as gi
      on gi.id = gui.installation_id
inner join tiers
      on tiers.id = gi.tier
where gui.user_id = $user_id
order by gi.login
