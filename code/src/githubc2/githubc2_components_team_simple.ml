module Primary = struct
  type t = {
    description : string option;
    html_url : string;
    id : int;
    ldap_dn : string option; [@default None]
    members_url : string;
    name : string;
    node_id : string;
    notification_setting : string option; [@default None]
    permission : string;
    privacy : string option; [@default None]
    repositories_url : string;
    slug : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
