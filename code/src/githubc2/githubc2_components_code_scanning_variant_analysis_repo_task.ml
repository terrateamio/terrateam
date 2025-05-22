module Primary = struct
  type t = {
    analysis_status : Githubc2_components_code_scanning_variant_analysis_status.t;
    artifact_size_in_bytes : int option; [@default None]
    artifact_url : string option; [@default None]
    database_commit_sha : string option; [@default None]
    failure_message : string option; [@default None]
    repository : Githubc2_components_simple_repository.t;
    result_count : int option; [@default None]
    source_location_prefix : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
