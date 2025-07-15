module Failed_relations = struct
  type t = Gitlabc_components_api_entities_projectimportfailedrelation.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Stats = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = {
  correlation_id : string option; [@default None]
  created_at : string option; [@default None]
  description : string option; [@default None]
  failed_relations : Failed_relations.t option; [@default None]
  id : int option; [@default None]
  import_error : string option; [@default None]
  import_status : string option; [@default None]
  import_type : string option; [@default None]
  name : string option; [@default None]
  name_with_namespace : string option; [@default None]
  path : string option; [@default None]
  path_with_namespace : string option; [@default None]
  stats : Stats.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
