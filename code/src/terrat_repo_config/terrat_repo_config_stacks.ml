module Names = struct
  include
    Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Terrat_repo_config_stack_config)
end

type t = {
  allow_workspace_in_multiple_stacks : bool; [@default false]
  names : Names.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
