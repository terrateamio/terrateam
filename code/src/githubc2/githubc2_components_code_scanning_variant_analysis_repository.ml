module Primary = struct
  type t = {
    full_name : string;
    id : int;
    name : string;
    private_ : bool; [@key "private"]
    stargazers_count : int;
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
