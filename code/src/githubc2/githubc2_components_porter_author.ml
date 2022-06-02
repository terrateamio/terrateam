module Primary = struct
  type t = {
    email : string;
    id : int;
    import_url : string;
    name : string;
    remote_id : string;
    remote_name : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
