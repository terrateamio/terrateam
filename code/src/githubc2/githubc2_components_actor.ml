module Primary = struct
  type t = {
    avatar_url : string;
    display_login : string option; [@default None]
    gravatar_id : string option; [@default None]
    id : int;
    login : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
