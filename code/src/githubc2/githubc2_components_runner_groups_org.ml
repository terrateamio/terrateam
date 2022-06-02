module Primary = struct
  type t = {
    allows_public_repositories : bool;
    default : bool;
    id : float;
    inherited : bool;
    inherited_allows_public_repositories : bool option; [@default None]
    name : string;
    runners_url : string;
    selected_repositories_url : string option; [@default None]
    visibility : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
