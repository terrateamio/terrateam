module Primary = struct
  module Position = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  type t = {
    author_id : int option; [@default None]
    commit_id : int option; [@default None]
    discussion_id : int option; [@default None]
    id : int option; [@default None]
    line_code : string option; [@default None]
    merge_request_id : int option; [@default None]
    note : string option; [@default None]
    position : Position.t option; [@default None]
    resolve_discussion : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
