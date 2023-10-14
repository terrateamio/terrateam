module Delete = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Fetch = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Method = struct
  let t_of_yojson = function
    | `String "cmd" -> Ok "cmd"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Store = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  delete : Delete.t option; [@default None]
  fetch : Fetch.t;
  method_ : Method.t; [@key "method"]
  store : Store.t;
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
