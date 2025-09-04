module Primary = struct
  module Exclude = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Repositories = struct
    type t = Githubc2_components_repository.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    archive_url : string option; [@default None]
    created_at : string;
    exclude : Exclude.t option; [@default None]
    exclude_attachments : bool;
    exclude_git_data : bool;
    exclude_metadata : bool;
    exclude_owner_projects : bool;
    exclude_releases : bool;
    guid : string;
    id : int64;
    lock_repositories : bool;
    node_id : string;
    org_metadata_only : bool;
    owner : Githubc2_components_nullable_simple_user.t option; [@default None]
    repositories : Repositories.t;
    state : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
