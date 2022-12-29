module Parent = struct
  module Privacy = struct
    let t_of_yojson = function
      | `String "open" -> Ok "open"
      | `String "closed" -> Ok "closed"
      | `String "secret" -> Ok "secret"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    description : string option;
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
    | `String "open" -> Ok "open"
    | `String "closed" -> Ok "closed"
    | `String "secret" -> Ok "secret"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  description : string option;
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
