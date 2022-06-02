module Primary = struct
  module Statuses = struct
    type t = Githubc2_components_simple_commit_status.t list
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    commit_url : string;
    repository : Githubc2_components_minimal_repository.t;
    sha : string;
    state : string;
    statuses : Statuses.t;
    total_count : int;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
