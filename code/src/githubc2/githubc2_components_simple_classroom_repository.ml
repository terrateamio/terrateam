module Primary = struct
  type t = {
    default_branch : string;
    full_name : string;
    html_url : string;
    id : int;
    node_id : string;
    private_ : bool; [@key "private"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
