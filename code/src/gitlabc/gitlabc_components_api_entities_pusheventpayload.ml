module Primary = struct
  type t = {
    action : string option; [@default None]
    commit_count : int option; [@default None]
    commit_from : string option; [@default None]
    commit_title : string option; [@default None]
    commit_to : string option; [@default None]
    ref_ : string option; [@default None] [@key "ref"]
    ref_count : int option; [@default None]
    ref_type : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
