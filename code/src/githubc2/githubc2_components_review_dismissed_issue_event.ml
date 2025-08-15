module Primary = struct
  module Dismissed_review = struct
    module Primary = struct
      type t = {
        dismissal_commit_id : string option; [@default None]
        dismissal_message : string option; [@default None]
        review_id : int;
        state : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    actor : Githubc2_components_simple_user.t;
    commit_id : string option; [@default None]
    commit_url : string option; [@default None]
    created_at : string;
    dismissed_review : Dismissed_review.t;
    event : string;
    id : int;
    node_id : string;
    performed_via_github_app : Githubc2_components_nullable_integration.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
