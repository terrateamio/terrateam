module Primary = struct
  type t = {
    payload : string option; [@default None]
    reason : string;
    signature : string option; [@default None]
    verified : bool;
    verified_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
