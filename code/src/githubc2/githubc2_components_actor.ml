module Primary = struct
  type t = {
    avatar_url : string;
    display_login : string option; [@default None]
    gravatar_id : string option;
    id : int;
    login : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
