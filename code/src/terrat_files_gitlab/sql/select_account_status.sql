select
    account_status,
    (trial_ends_at - current_date) as trial_end_days
from gitlab_installations
where id = $installation_id
