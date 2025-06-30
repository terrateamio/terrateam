module Primary = struct
  type t = {
    can_push : bool option; [@default None]
    expires_at : string option; [@default None]
    key : string;
    title : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
