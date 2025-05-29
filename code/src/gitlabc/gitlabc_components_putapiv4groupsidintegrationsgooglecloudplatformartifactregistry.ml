module Primary = struct
  type t = {
    artifact_registry_location : string;
    artifact_registry_project_id : string;
    artifact_registry_repositories : string;
    use_inherited_settings : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
