module Action = struct
  let t_of_yojson = function
    | `String "edited" -> Ok "edited"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Changes = struct
  module Body = struct
    type t = { from : string } [@@deriving yojson { strict = false; meta = true }, make, show]
  end

  type t = { body : Body.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, make, show]
end

module Issue_ = struct
  module All_of = struct
    module Primary = struct
      module Assignees = struct
        type t = Terrat_github_webhooks_user.t list
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Labels = struct
        type t = Terrat_github_webhooks_label.t list
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Pull_request_ = struct
        type t = {
          diff_url : string option; [@default None]
          html_url : string option; [@default None]
          merged_at : string option; [@default None]
          patch_url : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, make, show]
      end

      module State = struct
        let t_of_yojson = function
          | `String "open" -> Ok "open"
          | `String "closed" -> Ok "closed"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        active_lock_reason : string option;
        assignee : Terrat_github_webhooks_user.t option; [@default None]
        assignees : Assignees.t option; [@default None]
        author_association : string;
        body : string option; [@default None]
        closed_at : string option; [@default None]
        comments : int;
        comments_url : string;
        created_at : string;
        draft : bool option; [@default None]
        events_url : string;
        html_url : string;
        id : int;
        labels : Labels.t;
        labels_url : string;
        locked : bool;
        milestone : Terrat_github_webhooks_milestone.t option; [@default None]
        node_id : string;
        number : int;
        performed_via_github_app : Terrat_github_webhooks_app.t option; [@default None]
        pull_request : Pull_request_.t option; [@default None]
        reactions : Terrat_github_webhooks_reactions.t;
        repository_url : string;
        state : State.t;
        state_reason : string option; [@default None]
        timeline_url : string option; [@default None]
        title : string;
        updated_at : string;
        url : string;
        user : Terrat_github_webhooks_user.t;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Assignees = struct
        type t = Terrat_github_webhooks_user.t list
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Labels = struct
        type t = Terrat_github_webhooks_label.t list
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Pull_request_ = struct
        type t = {
          diff_url : string option; [@default None]
          html_url : string option; [@default None]
          merged_at : string option; [@default None]
          patch_url : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, make, show]
      end

      module State = struct
        let t_of_yojson = function
          | `String "open" -> Ok "open"
          | `String "closed" -> Ok "closed"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        active_lock_reason : string option;
        assignee : Terrat_github_webhooks_user.t option; [@default None]
        assignees : Assignees.t option; [@default None]
        author_association : string;
        body : string option; [@default None]
        closed_at : string option; [@default None]
        comments : int;
        comments_url : string;
        created_at : string;
        draft : bool option; [@default None]
        events_url : string;
        html_url : string;
        id : int;
        labels : Labels.t;
        labels_url : string;
        locked : bool;
        milestone : Terrat_github_webhooks_milestone.t option; [@default None]
        node_id : string;
        number : int;
        performed_via_github_app : Terrat_github_webhooks_app.t option; [@default None]
        pull_request : Pull_request_.t option; [@default None]
        reactions : Terrat_github_webhooks_reactions.t;
        repository_url : string;
        state : State.t;
        state_reason : string option; [@default None]
        timeline_url : string option; [@default None]
        title : string;
        updated_at : string;
        url : string;
        user : Terrat_github_webhooks_user.t;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

type t = {
  action : Action.t;
  changes : Changes.t;
  comment : Terrat_github_webhooks_issue_comment.t;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  issue : Issue_.t;
  organization : Terrat_github_webhooks_organization.t option; [@default None]
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
