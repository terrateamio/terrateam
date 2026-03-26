module Parent = struct
  module Privacy = struct
    let t_of_yojson = function
      | `String "closed" -> Ok `Closed
      | `String "open" -> Ok `Open
      | `String "secret" -> Ok `Secret
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Closed -> `String "closed"
      | `Open -> `String "open"
      | `Secret -> `String "secret"

    type t =
      ([ `Closed
       | `Open
       | `Secret
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    description : string option; [@default None]
    html_url : string;
    id : int;
    members_url : string;
    name : string;
    node_id : string;
    permission : string;
    privacy : Privacy.t;
    repositories_url : string;
    slug : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

module Privacy = struct
  let t_of_yojson = function
    | `String "closed" -> Ok `Closed
    | `String "open" -> Ok `Open
    | `String "secret" -> Ok `Secret
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Closed -> `String "closed"
    | `Open -> `String "open"
    | `Secret -> `String "secret"

  type t =
    ([ `Closed
     | `Open
     | `Secret
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  description : string option; [@default None]
  html_url : string;
  id : int;
  members_url : string;
  name : string;
  node_id : string;
  parent : Parent.t option; [@default None]
  permission : string;
  privacy : Privacy.t;
  repositories_url : string;
  slug : string;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
