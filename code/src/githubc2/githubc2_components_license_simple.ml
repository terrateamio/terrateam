module Primary = struct
  type t = {
    html_url : string option; [@default None]
    key : string;
    name : string;
    node_id : string;
    spdx_id : string option;
    url : string option;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
