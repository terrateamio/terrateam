module Additional = struct
  type t = {
    tags : Terrat_repo_config_tags.t option; [@default None]
    when_modified : Terrat_repo_config_when_modified_nullable.t option; [@default None]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
