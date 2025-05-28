module Primary = struct
  type t = {
    payload : string option;
    reason : string;
    signature : string option;
    verified : bool;
    verified_at : string option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
