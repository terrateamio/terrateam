module Action = struct
  let t_of_yojson = function
    | `String "added" -> Ok "added"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Repositories_added = struct
  module Items = struct
    type t = {
      full_name : string;
      id : int;
      name : string;
      node_id : string;
      private_ : bool; [@key "private"]
    }
    [@@deriving yojson { strict = false; meta = true }, make, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Repositories_removed = struct
  module Items = struct
    type t = {
      full_name : string option; [@default None]
      id : int option; [@default None]
      name : string option; [@default None]
      node_id : string option; [@default None]
      private_ : bool option; [@key "private"] [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, make, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Repository_selection = struct
  let t_of_yojson = function
    | `String "all" -> Ok "all"
    | `String "selected" -> Ok "selected"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  installation : Terrat_github_webhooks_installation.t;
  repositories_added : Repositories_added.t;
  repositories_removed : Repositories_removed.t;
  repository_selection : Repository_selection.t;
  requester : Terrat_github_webhooks_user.t option; [@default None]
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
