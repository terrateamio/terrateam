module Primary = struct
  type t = {
    confidential : bool; [@default true]
    name : string;
    redirect_uri : string;
    scopes : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
