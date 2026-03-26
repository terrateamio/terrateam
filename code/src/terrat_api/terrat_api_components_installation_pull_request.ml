module State = struct
  let t_of_yojson = function
    | `String "closed" -> Ok `Closed
    | `String "merged" -> Ok `Merged
    | `String "open" -> Ok `Open
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Closed -> `String "closed"
    | `Merged -> `String "merged"
    | `Open -> `String "open"

  type t =
    ([ `Closed
     | `Merged
     | `Open
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  base_branch : string;
  base_sha : string;
  branch : string;
  latest_work_manifest_run_at : string option; [@default None]
  merged_at : string option; [@default None]
  merged_sha : string option; [@default None]
  name : string;
  owner : string;
  pull_number : int;
  repository : int;
  sha : string;
  state : State.t;
  title : string option; [@default None]
  user : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
