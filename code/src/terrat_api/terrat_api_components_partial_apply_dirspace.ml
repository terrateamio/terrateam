module State =
  struct
    let t_of_yojson =
      function
      | `String "plan_pending" -> Ok "plan_pending"
      | `String "plan_failed" -> Ok "plan_failed"
      | `String "apply_pending" -> Ok "apply_pending"
      | `String "apply_failed" -> Ok "apply_failed"
      | `String "apply_success" -> Ok "apply_success"
      | json ->
          Error ("Unknown value: " ^ (Yojson.Safe.pretty_to_string json))
    type t = ((string)[@of_yojson t_of_yojson])[@@deriving
                                                 ((yojson
                                                     {
                                                       strict = false;
                                                       meta = true
                                                     }), show, eq)]
  end
type t = {
  path: string ;
  state: State.t ;
  workspace: string }[@@deriving
                       ((yojson { strict = false; meta = true }), show, eq)]
