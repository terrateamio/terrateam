module Added = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
end

module Modified = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
end

module Removed = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  added : Added.t;
  author : Terrat_github_webhooks_committer.t;
  committer : Terrat_github_webhooks_committer.t;
  distinct : bool;
  id : string;
  message : string;
  modified : Modified.t;
  removed : Removed.t;
  timestamp : string;
  tree_id : string;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
