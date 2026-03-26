module Primary = struct
  module Answer_chosen_by = struct
    module Primary = struct
      module Type = struct
        let t_of_yojson = function
          | `String "Bot" -> Ok `Bot
          | `String "Organization" -> Ok `Organization
          | `String "User" -> Ok `User
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Bot -> `String "Bot"
          | `Organization -> `String "Organization"
          | `User -> `String "User"

        type t =
          ([ `Bot
           | `Organization
           | `User
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
      | `String "COLLABORATOR" -> Ok `COLLABORATOR
      | `String "CONTRIBUTOR" -> Ok `CONTRIBUTOR
      | `String "FIRST_TIMER" -> Ok `FIRST_TIMER
      | `String "FIRST_TIME_CONTRIBUTOR" -> Ok `FIRST_TIME_CONTRIBUTOR
      | `String "MANNEQUIN" -> Ok `MANNEQUIN
      | `String "MEMBER" -> Ok `MEMBER
      | `String "NONE" -> Ok `NONE
      | `String "OWNER" -> Ok `OWNER
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `COLLABORATOR -> `String "COLLABORATOR"
      | `CONTRIBUTOR -> `String "CONTRIBUTOR"
      | `FIRST_TIMER -> `String "FIRST_TIMER"
      | `FIRST_TIME_CONTRIBUTOR -> `String "FIRST_TIME_CONTRIBUTOR"
      | `MANNEQUIN -> `String "MANNEQUIN"
      | `MEMBER -> `String "MEMBER"
      | `NONE -> `String "NONE"
      | `OWNER -> `String "OWNER"

    type t =
      ([ `COLLABORATOR
       | `CONTRIBUTOR
       | `FIRST_TIMER
       | `FIRST_TIME_CONTRIBUTOR
       | `MANNEQUIN
       | `MEMBER
       | `NONE
       | `OWNER
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
      | `String "closed" -> Ok `Closed
      | `String "converting" -> Ok `Converting
      | `String "locked" -> Ok `Locked
      | `String "open" -> Ok `Open
      | `String "transferring" -> Ok `Transferring
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Closed -> `String "closed"
      | `Converting -> `String "converting"
      | `Locked -> `String "locked"
      | `Open -> `String "open"
      | `Transferring -> `String "transferring"

    type t =
      ([ `Closed
       | `Converting
       | `Locked
       | `Open
       | `Transferring
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State_reason = struct
    let t_of_yojson = function
      | `String "duplicate" -> Ok `Duplicate
      | `String "outdated" -> Ok `Outdated
      | `String "reopened" -> Ok `Reopened
      | `String "resolved" -> Ok `Resolved
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Duplicate -> `String "duplicate"
      | `Outdated -> `String "outdated"
      | `Reopened -> `String "reopened"
      | `Resolved -> `String "resolved"

    type t =
      ([ `Duplicate
       | `Outdated
       | `Reopened
       | `Resolved
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module User = struct
    module Primary = struct
      module Type = struct
        let t_of_yojson = function
          | `String "Bot" -> Ok `Bot
          | `String "Organization" -> Ok `Organization
          | `String "User" -> Ok `User
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Bot -> `String "Bot"
          | `Organization -> `String "Organization"
          | `User -> `String "User"

        type t =
          ([ `Bot
           | `Organization
           | `User
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
