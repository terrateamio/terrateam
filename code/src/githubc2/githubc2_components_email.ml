module Primary = struct
  type t = {
    email : string;
    primary : bool;
    verified : bool;
    visibility : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
