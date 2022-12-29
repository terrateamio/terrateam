module Primary = struct
  module Comments = struct
    type t = Githubc2_components_commit_comment.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    comments : Comments.t option; [@default None]
    commit_id : string option; [@default None]
    event : string option; [@default None]
    node_id : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
