module Primary = struct
  type t = {
    allows_public_repositories : bool;
    default : bool;
    id : float;
    name : string;
    runners_url : string;
    selected_organizations_url : string option; [@default None]
    visibility : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
