module Primary = struct
  type t = {
    commit_oid : string option; [@default None]
    content_type : string;
    created_at : string;
    id : int;
    language : string;
    name : string;
    size : int;
    updated_at : string;
    uploader : Githubc2_components_simple_user.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
