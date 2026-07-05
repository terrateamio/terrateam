-- Extend repo_configs so it stores two kinds of row:
--
--   'built'   - the existing build-config cache, keyed (installation, sha),
--               expired after a day by the repo config cleanup loop.
--   'derived' - a history of the fully-derived repo config (the
--               `terrateam repo-config` output), keyed
--               (installation, repo, branch, sha) so it can be analyzed by
--               org/repo/branch over time, expired after 90 days by the repo
--               config cleanup loop.
--
-- The two kinds have different uniqueness grains, so the single
-- (installation, sha) primary key is replaced by a partial unique index per
-- kind.

alter table repo_configs
      add column kind text not null default 'built',
      add column repo uuid,
      add column branch text;

alter table repo_configs
      drop constraint repo_configs_pkey,
      drop constraint repo_configs_fut_pkey;

create unique index repo_configs_built_key
       on repo_configs (installation, sha)
       where kind = 'built';

create unique index repo_configs_derived_key
       on repo_configs (installation, repo, branch, sha)
       where kind = 'derived';

-- The per-VCS build-cache views now only expose 'built' rows so the existing
-- read path (select_repo_config.sql) never sees history rows.

create or replace view github_repo_configs as
       select
        gim.installation_id as installation_id,
        rc.sha as sha,
        rc.created_at as created_at,
        rc.data as data
       from repo_configs as rc
       inner join github_installations_map as gim
             on rc.installation = gim.core_id
       where rc.kind = 'built';

create or replace view gitlab_repo_configs as
       select
        gim.installation_id as installation_id,
        rc.sha as sha,
        rc.created_at as created_at,
        rc.data as data
       from repo_configs as rc
       inner join gitlab_installations_map as gim
             on rc.installation = gim.core_id
       where rc.kind = 'built';
