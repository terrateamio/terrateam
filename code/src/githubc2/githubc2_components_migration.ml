module Primary = struct
  module Exclude = struct
    module Items = struct
      type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Repositories = struct
    type t = Githubc2_components_repository.t list
    [@@deriving yojson { strict = false; meta = true }, show]
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
    id : int;
    lock_repositories : bool;
    node_id : string;
    owner : Githubc2_components_nullable_simple_user.t option;
    repositories : Repositories.t;
    state : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
