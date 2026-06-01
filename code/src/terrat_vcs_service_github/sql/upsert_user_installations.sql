-- Record the installations a user belongs to, keyed off the authoritative list
-- GitHub reported for this user ($installation_ids).
--
-- This is intentionally ADDITIVE ONLY (mirrors the repository refresh): it never
-- deletes memberships. An empty or partial $installation_ids (transient GitHub
-- error, eventual consistency, or the brand-new-install webhook race) must never
-- be able to wipe a user's existing membership — doing so previously dropped the
-- user into demo mode and emptied every user-scoped view. Pruning memberships for
-- orgs a user has genuinely left is handled out-of-band, not on this hot path.
--
-- The inner join on github_installations is required by the
-- github_user_installations2.installation_id foreign key: we can only record
-- membership for an installation whose row already exists locally (created by the
-- installation webhook).
with
all_installation_ids as (
    select t.id from unnest($installation_ids) as t(id)
    inner join github_installations as gi
        on gi.id = t.id
),
inserted as (
    insert into github_user_installations2 (user_id, installation_id)
    select $user_id, id from all_installation_ids
    on conflict (user_id, installation_id) do nothing
)
select
    gi.id,
    gi.login,
    gi.state
from all_installation_ids as ai
inner join github_installations as gi
    on gi.id = ai.id
