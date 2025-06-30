module DeleteApiV4Runners = struct
  module Parameters = struct
    type t = { token : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Forbidden = struct end

    type t =
      [ `No_content
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/runners"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("token", Var (params.token, String)) ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4Runners = struct
  module Parameters = struct
    type t = { postapiv4runners : Gitlabc_components.PostApiV4Runners.t [@key "postApiV4Runners"] }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Gone = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Forbidden
      | `Gone
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("410", fun _ -> Ok `Gone);
      ]
  end

  let url = "/api/v4/runners"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4Runners = struct
  module Parameters = struct
    module Scope = struct
      let t_of_yojson = function
        | `String "specific" -> Ok "specific"
        | `String "shared" -> Ok "shared"
        | `String "instance_type" -> Ok "instance_type"
        | `String "group_type" -> Ok "group_type"
        | `String "project_type" -> Ok "project_type"
        | `String "active" -> Ok "active"
        | `String "paused" -> Ok "paused"
        | `String "online" -> Ok "online"
        | `String "offline" -> Ok "offline"
        | `String "never_contacted" -> Ok "never_contacted"
        | `String "stale" -> Ok "stale"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

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
      page : int; [@default 1]
      paused : bool option; [@default None]
      per_page : int; [@default 20]
      scope : Scope.t option; [@default None]
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
    module Unauthorized = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
      ]
  end

  let url = "/api/v4/runners"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("scope", Var (params.scope, Option String));
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

module GetApiV4RunnersAll = struct
  module Parameters = struct
    module Scope = struct
      let t_of_yojson = function
        | `String "specific" -> Ok "specific"
        | `String "shared" -> Ok "shared"
        | `String "instance_type" -> Ok "instance_type"
        | `String "group_type" -> Ok "group_type"
        | `String "project_type" -> Ok "project_type"
        | `String "active" -> Ok "active"
        | `String "paused" -> Ok "paused"
        | `String "online" -> Ok "online"
        | `String "offline" -> Ok "offline"
        | `String "never_contacted" -> Ok "never_contacted"
        | `String "stale" -> Ok "stale"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

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
      page : int; [@default 1]
      paused : bool option; [@default None]
      per_page : int; [@default 20]
      scope : Scope.t option; [@default None]
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
    module Unauthorized = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
      ]
  end

  let url = "/api/v4/runners/all"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("scope", Var (params.scope, Option String));
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

module DeleteApiV4RunnersManagers = struct
  module Parameters = struct
    type t = {
      system_id : string;
      token : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/runners/managers"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("token", Var (params.token, String)); ("system_id", Var (params.system_id, String)) ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PostApiV4RunnersResetAuthenticationToken = struct
  module Parameters = struct
    type t = {
      postapiv4runnersresetauthenticationtoken :
        Gitlabc_components.PostApiV4RunnersResetAuthenticationToken.t;
          [@key "postApiV4RunnersResetAuthenticationToken"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Forbidden = struct end

    type t =
      [ `Created
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/runners/reset_authentication_token"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4RunnersResetRegistrationToken = struct
  module Parameters = struct end

  module Responses = struct
    module Created = struct end
    module Forbidden = struct end

    type t =
      [ `Created
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created); ("403", fun _ -> Ok `Forbidden) ]
  end

  let url = "/api/v4/runners/reset_registration_token"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4RunnersVerify = struct
  module Parameters = struct
    type t = {
      postapiv4runnersverify : Gitlabc_components.PostApiV4RunnersVerify.t;
          [@key "postApiV4RunnersVerify"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Forbidden = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Forbidden
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("403", fun _ -> Ok `Forbidden);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/runners/verify"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4RunnersId = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Precondition_failed = struct end

    type t =
      [ `No_content
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Precondition_failed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("412", fun _ -> Ok `Precondition_failed);
      ]
  end

  let url = "/api/v4/runners/{id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4RunnersId = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4runnersid : Gitlabc_components.PutApiV4RunnersId.t; [@key "putApiV4RunnersId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/runners/{id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4RunnersId = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/runners/{id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
