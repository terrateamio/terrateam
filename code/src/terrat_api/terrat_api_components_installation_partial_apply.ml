module Applied_dirspaces =
  struct
    type t = Terrat_api_components_partial_apply_dirspace.t list[@@deriving
                                                                  ((yojson
                                                                    {
                                                                    strict =
                                                                    false;
                                                                    meta =
                                                                    true
                                                                    }), show,
                                                                    eq)]
  end
module State =
  struct
    let t_of_yojson =
      function
      | `String "open" -> Ok "open"
      | `String "closed" -> Ok "closed"
      | `String "merged" -> Ok "merged"
      | json ->
          Error ("Unknown value: " ^ (Yojson.Safe.pretty_to_string json))
    type t = ((string)[@of_yojson t_of_yojson])[@@deriving
                                                 ((yojson
                                                     {
                                                       strict = false;
                                                       meta = true
                                                     }), show, eq)]
  end
module Unapplied_dirspaces =
  struct
    type t = Terrat_api_components_partial_apply_dirspace.t list[@@deriving
                                                                  ((yojson
                                                                    {
                                                                    strict =
                                                                    false;
                                                                    meta =
                                                                    true
                                                                    }), show,
                                                                    eq)]
  end
type t =
  {
  applied_dirspaces: Applied_dirspaces.t ;
  base_branch: string ;
  base_sha: string ;
  branch: string ;
  name: string ;
  owner: string ;
  pull_number: int ;
  repository: int ;
  sha: string ;
  state: State.t ;
  title: string option [@default None];
  unapplied_dirspaces: Unapplied_dirspaces.t ;
  user: string option [@default None]}[@@deriving
                                        ((yojson
                                            { strict = false; meta = true }),
                                          show, eq)]
