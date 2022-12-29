module Action = struct
  let t_of_yojson = function
    | `String "deleted" -> Ok "deleted"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Repositories = struct
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

module Requester = struct
  type t = unit [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  installation : Terrat_github_webhooks_installation.t;
  repositories : Repositories.t option; [@default None]
  requester : Requester.t option; [@default None]
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
