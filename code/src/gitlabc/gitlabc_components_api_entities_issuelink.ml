module Primary = struct
  type t = {
    link_type : string option; [@default None]
    source_issue : Gitlabc_components_api_entities_issuebasic.t option; [@default None]
    target_issue : Gitlabc_components_api_entities_issuebasic.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
