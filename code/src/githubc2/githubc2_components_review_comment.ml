module Primary = struct
  module Links_ = struct
    module Primary = struct
      type t = {
        html : Githubc2_components_link.t;
        pull_request : Githubc2_components_link.t;
        self : Githubc2_components_link.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Side = struct
    let t_of_yojson = function
      | `String "LEFT" -> Ok "LEFT"
      | `String "RIGHT" -> Ok "RIGHT"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Start_side = struct
    let t_of_yojson = function
      | `String "LEFT" -> Ok "LEFT"
      | `String "RIGHT" -> Ok "RIGHT"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    links_ : Links_.t; [@key "_links"]
    author_association : Githubc2_components_author_association.t;
    body : string;
    body_html : string option; [@default None]
    body_text : string option; [@default None]
    commit_id : string;
    created_at : string;
    diff_hunk : string;
    html_url : string;
    id : int64;
    in_reply_to_id : int option; [@default None]
    line : int option; [@default None]
    node_id : string;
    original_commit_id : string;
    original_line : int option; [@default None]
    original_position : int;
    original_start_line : int option; [@default None]
    path : string;
    position : int option;
    pull_request_review_id : int64 option;
    pull_request_url : string;
    reactions : Githubc2_components_reaction_rollup.t option; [@default None]
    side : Side.t; [@default "RIGHT"]
    start_line : int option; [@default None]
    start_side : Start_side.t option; [@default Some "RIGHT"]
    updated_at : string;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
