module Schedules = struct
  include
    Json_schema.Additional_properties.Make
      (Json_schema.Empty_obj)
      (Terrat_repo_config_drift_schedule)
end

type t = {
  enabled : bool; [@default false]
  schedules : Schedules.t;
}
(* strict = false so Stategraph-owned drift keys (e.g. ai_analysis, reconcile_pr)
   in the .stategraph/config.yml drift block are accepted and ignored here;
   Stategraph reads them from the raw config. *)
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
