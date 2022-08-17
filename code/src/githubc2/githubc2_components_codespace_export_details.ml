module Primary = struct
  type t = {
    branch : string option; [@default None]
    completed_at : string option; [@default None]
    export_url : string option; [@default None]
    html_url : string option; [@default None]
    id : string option; [@default None]
    sha : string option; [@default None]
    state : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
