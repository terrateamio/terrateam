module Primary = struct
  module Answer_chosen_by = struct
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
        id : int;
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

  module Category = struct
    module Primary = struct
      type t = {
        created_at : string;
        description : string;
        emoji : string;
        id : int;
        is_answerable : bool;
        name : string;
        node_id : string option; [@default None]
        repository_id : int;
        slug : string;
        updated_at : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Labels = struct
    type t = Githubc2_components_label.t list
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

  module State = struct
    let t_of_yojson = function
      | `String "open" -> Ok "open"
      | `String "closed" -> Ok "closed"
      | `String "locked" -> Ok "locked"
      | `String "converting" -> Ok "converting"
      | `String "transferring" -> Ok "transferring"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State_reason = struct
    let t_of_yojson = function
      | `String "resolved" -> Ok "resolved"
      | `String "outdated" -> Ok "outdated"
      | `String "duplicate" -> Ok "duplicate"
      | `String "reopened" -> Ok "reopened"
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
    active_lock_reason : string option; [@default None]
    answer_chosen_at : string option; [@default None]
    answer_chosen_by : Answer_chosen_by.t option; [@default None]
    answer_html_url : string option; [@default None]
    author_association : Author_association_.t;
    body : string;
    category : Category.t;
    comments : int;
    created_at : string;
    html_url : string;
    id : int;
    labels : Labels.t option; [@default None]
    locked : bool;
    node_id : string;
    number : int;
    reactions : Reactions.t option; [@default None]
    repository_url : string;
    state : State.t;
    state_reason : State_reason.t option; [@default None]
    timeline_url : string option; [@default None]
    title : string;
    updated_at : string;
    user : User.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
