module Primary = struct
  module Rules = struct
    type t = Gitlabc_components_ee_api_entities_mergerequestapprovalstaterule.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    approval_rules_overwritten : bool option; [@default None]
    rules : Rules.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
