module Primary = struct
  module Workflow_run_ = struct
    module Primary = struct
      type t = {
        head_branch : string option; [@default None]
        head_repository_id : int option; [@default None]
        head_sha : string option; [@default None]
        id : int option; [@default None]
        repository_id : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    archive_download_url : string;
    created_at : string option; [@default None]
    digest : string option; [@default None]
    expired : bool;
    expires_at : string option; [@default None]
    id : int;
    name : string;
    node_id : string;
    size_in_bytes : int;
    updated_at : string option; [@default None]
    url : string;
    workflow_run : Workflow_run_.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
