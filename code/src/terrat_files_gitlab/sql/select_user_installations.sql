select
  gi.id,
  gi.login,
  gi.account_status,
  to_char(gi.trial_ends_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as trial_ends_at,
  tiers.name,
  tiers.features
from gitlab_installations as gi
inner join tiers
      on tiers.id = gi.tier
where gi.id = ANY($installation_ids)
