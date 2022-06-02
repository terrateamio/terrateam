module Primary = struct
  type t = {
    html_url : string option;
    key : string;
    name : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
