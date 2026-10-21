-- RFD 2716: a remote state reference in the address of a [terraform_remote_state]
-- data source.
--
-- 2026-09-23-add-tf-module-tables.sql (lines 16-20) says a body row carries no
-- call site, and that [remote_tf_state_refs] and [remote_state_id] are a remote
-- state resolved for the call. This column makes that split exact. The body row
-- carries only the map of address to outputs refs: the block's own text, the
-- same at every call path. It never carries a resolved state id. That stays in
-- the per-call-path resolved-key map, because two calls with two arguments can
-- resolve two states. "One body row then serves every call" still holds for
-- resolution.
--
-- Backwards compatible. The column is nullable.

alter table tf_module_hcl add column if not exists remote_tf_state_refs jsonb;
