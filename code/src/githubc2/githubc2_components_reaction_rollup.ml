module Primary = struct
  type t = {
    plus_one : int; [@key "+1"]
    minus_one : int; [@key "-1"]
    confused : int;
    eyes : int;
    heart : int;
    hooray : int;
    laugh : int;
    rocket : int;
    total_count : int;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
