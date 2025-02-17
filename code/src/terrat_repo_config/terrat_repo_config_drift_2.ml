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
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
