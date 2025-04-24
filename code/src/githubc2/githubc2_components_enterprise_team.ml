module Primary = struct
  type t = {
    created_at : string;
    group_id : string option; [@default None]
    group_name : string option; [@default None]
    html_url : string;
    id : int64;
    members_url : string;
    name : string;
    slug : string;
    sync_to_organizations : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
