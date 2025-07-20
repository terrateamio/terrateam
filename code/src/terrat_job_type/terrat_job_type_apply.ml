module Type_ = struct
  let t_of_yojson = function
    | `String "apply" -> Ok "apply"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  force : bool; [@default false]
  kind : Terrat_job_type_kind.t option; [@default None]
  tag_query : string option; [@default None]
  type_ : Type_.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
