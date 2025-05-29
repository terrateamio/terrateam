module Primary = struct
  type t = {
    created_at : string option; [@default None]
    description : string option; [@default None]
    due_date : string option; [@default None]
    group_id : string option; [@default None]
    id : string option; [@default None]
    iid : string option; [@default None]
    sequence : string option; [@default None]
    start_date : string option; [@default None]
    state : string option; [@default None]
    title : string option; [@default None]
    updated_at : string option; [@default None]
    web_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
