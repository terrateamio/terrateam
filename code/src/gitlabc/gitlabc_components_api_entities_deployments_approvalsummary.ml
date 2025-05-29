module Primary = struct
  type t = {
    rules : Gitlabc_components_api_entities_protectedenvironments_approvalruleforsummary.t option;
        [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
