module GetApiV4UsersIdEvents = struct
  module Parameters = struct
    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Target_type = struct
      let t_of_yojson = function
        | `String "issue" -> Ok "issue"
        | `String "milestone" -> Ok "milestone"
        | `String "merge_request" -> Ok "merge_request"
        | `String "note" -> Ok "note"
        | `String "project" -> Ok "project"
        | `String "snippet" -> Ok "snippet"
        | `String "user" -> Ok "user"
        | `String "wiki" -> Ok "wiki"
        | `String "design" -> Ok "design"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      action : string option; [@default None]
      after : string option; [@default None]
      before : string option; [@default None]
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      sort : Sort.t; [@default "desc"]
      target_type : Target_type.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/users/{id}/events"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("action", Var (params.action, Option String));
           ("target_type", Var (params.target_type, Option String));
           ("before", Var (params.before, Option String));
           ("after", Var (params.after, Option String));
           ("sort", Var (params.sort, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
