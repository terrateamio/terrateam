module GetApiV4GroupsIdRunners = struct
  module Parameters = struct
    module Status = struct
      let t_of_yojson = function
        | `String "active" -> Ok "active"
        | `String "paused" -> Ok "paused"
        | `String "online" -> Ok "online"
        | `String "offline" -> Ok "offline"
        | `String "never_contacted" -> Ok "never_contacted"
        | `String "stale" -> Ok "stale"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Tag_list = struct
      type t = string list [@@deriving show, eq]
    end

    module Type = struct
      let t_of_yojson = function
        | `String "instance_type" -> Ok "instance_type"
        | `String "group_type" -> Ok "group_type"
        | `String "project_type" -> Ok "project_type"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      paused : bool option; [@default None]
      per_page : int; [@default 20]
      status : Status.t option; [@default None]
      tag_list : Tag_list.t option; [@default None]
      type_ : Type.t option; [@default None] [@key "type"]
      version_prefix : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("400", fun _ -> Ok `Bad_request); ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/groups/{id}/runners"

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
           ("type", Var (params.type_, Option String));
           ("paused", Var (params.paused, Option Bool));
           ("status", Var (params.status, Option String));
           ("tag_list", Var (params.tag_list, Option (Array String)));
           ("version_prefix", Var (params.version_prefix, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4GroupsIdRunnersResetRegistrationToken = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/runners/reset_registration_token"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end
