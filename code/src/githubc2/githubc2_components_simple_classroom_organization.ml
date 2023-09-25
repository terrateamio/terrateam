module Primary = struct
  type t = {
    avatar_url : string;
    html_url : string;
    id : int;
    login : string;
    name : string option;
    node_id : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
