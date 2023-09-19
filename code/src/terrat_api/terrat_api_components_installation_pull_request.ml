module State = struct
  let t_of_yojson = function
    | `String "open" -> Ok "open"
    | `String "closed" -> Ok "closed"
    | `String "merged" -> Ok "merged"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
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
[@@deriving yojson { strict = true; meta = true }, show, eq]
