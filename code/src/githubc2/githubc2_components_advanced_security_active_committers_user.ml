module Primary = struct
  type t = {
    last_pushed_date : string;
    user_login : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
