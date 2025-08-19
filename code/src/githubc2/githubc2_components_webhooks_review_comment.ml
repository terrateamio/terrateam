module Primary = struct
  module Links_ = struct
    module Primary = struct
      module Html = struct
        module Primary = struct
          type t = { href : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Pull_request_ = struct
        module Primary = struct
          type t = { href : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Self = struct
        module Primary = struct
          type t = { href : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        html : Html.t;
        pull_request : Pull_request_.t;
        self : Self.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Author_association_ = struct
    let t_of_yojson = function
      | `String "COLLABORATOR" -> Ok "COLLABORATOR"
      | `String "CONTRIBUTOR" -> Ok "CONTRIBUTOR"
      | `String "FIRST_TIMER" -> Ok "FIRST_TIMER"
      | `String "FIRST_TIME_CONTRIBUTOR" -> Ok "FIRST_TIME_CONTRIBUTOR"
      | `String "MANNEQUIN" -> Ok "MANNEQUIN"
      | `String "MEMBER" -> Ok "MEMBER"
      | `String "NONE" -> Ok "NONE"
      | `String "OWNER" -> Ok "OWNER"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Reactions = struct
    module Primary = struct
      type t = {
        plus_one : int; [@key "+1"]
        minus_one : int; [@key "-1"]
        confused : int;
        eyes : int;
        heart : int;
        hooray : int;
        laugh : int;
        rocket : int;
        total_count : int;
        url : string;
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

  module Subject_type = struct
    let t_of_yojson = function
      | `String "line" -> Ok "line"
      | `String "file" -> Ok "file"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module User = struct
    module Primary = struct
      module Type = struct
        let t_of_yojson = function
          | `String "Bot" -> Ok "Bot"
          | `String "User" -> Ok "User"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        avatar_url : string option; [@default None]
        deleted : bool option; [@default None]
        email : string option; [@default None]
        events_url : string option; [@default None]
        followers_url : string option; [@default None]
        following_url : string option; [@default None]
        gists_url : string option; [@default None]
        gravatar_id : string option; [@default None]
        html_url : string option; [@default None]
        id : int64;
        login : string;
        name : string option; [@default None]
        node_id : string option; [@default None]
        organizations_url : string option; [@default None]
        received_events_url : string option; [@default None]
        repos_url : string option; [@default None]
        site_admin : bool option; [@default None]
        starred_url : string option; [@default None]
        subscriptions_url : string option; [@default None]
        type_ : Type.t option; [@default None] [@key "type"]
        url : string option; [@default None]
        user_view_type : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    links_ : Links_.t; [@key "_links"]
    author_association : Author_association_.t;
    body : string;
    commit_id : string;
    created_at : string;
    diff_hunk : string;
    html_url : string;
    id : int;
    in_reply_to_id : int option; [@default None]
    line : int option; [@default None]
    node_id : string;
    original_commit_id : string;
    original_line : int;
    original_position : int;
    original_start_line : int option; [@default None]
    path : string;
    position : int option; [@default None]
    pull_request_review_id : int option; [@default None]
    pull_request_url : string;
    reactions : Reactions.t;
    side : Side.t;
    start_line : int option; [@default None]
    start_side : Start_side.t option; [@default Some "RIGHT"]
    subject_type : Subject_type.t option; [@default None]
    updated_at : string;
    url : string;
    user : User.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
