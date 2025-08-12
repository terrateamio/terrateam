module PostApiV4ProjectsIdHooks = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4ProjectsIdHooks.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/hooks"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
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

module GetApiV4ProjectsIdHooks = struct
  module Parameters = struct
    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/hooks"

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
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdHooksHookId = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("hook_id", Var (params.hook_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdHooksHookId = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PutApiV4ProjectsIdHooksHookId.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("hook_id", Var (params.hook_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdHooksHookId = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : string;
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

  let url = "/api/v4/projects/{id}/hooks/{hook_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("hook_id", Var (params.hook_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdHooksHookIdCustomHeadersKey = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : int;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/custom_headers/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("hook_id", Var (params.hook_id, Int));
           ("key", Var (params.key, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdHooksHookIdCustomHeadersKey = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : int;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PutApiV4ProjectsIdHooksHookIdCustomHeadersKey.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/custom_headers/{key}"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("hook_id", Var (params.hook_id, Int));
           ("key", Var (params.key, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4ProjectsIdHooksHookIdEvents = struct
  module Parameters = struct
    module Status = struct
      module Items = struct
        let t_of_yojson = function
          | `String "100" -> Ok "100"
          | `String "101" -> Ok "101"
          | `String "102" -> Ok "102"
          | `String "103" -> Ok "103"
          | `String "200" -> Ok "200"
          | `String "201" -> Ok "201"
          | `String "202" -> Ok "202"
          | `String "203" -> Ok "203"
          | `String "204" -> Ok "204"
          | `String "205" -> Ok "205"
          | `String "206" -> Ok "206"
          | `String "207" -> Ok "207"
          | `String "208" -> Ok "208"
          | `String "226" -> Ok "226"
          | `String "300" -> Ok "300"
          | `String "301" -> Ok "301"
          | `String "302" -> Ok "302"
          | `String "303" -> Ok "303"
          | `String "304" -> Ok "304"
          | `String "305" -> Ok "305"
          | `String "306" -> Ok "306"
          | `String "307" -> Ok "307"
          | `String "308" -> Ok "308"
          | `String "400" -> Ok "400"
          | `String "401" -> Ok "401"
          | `String "402" -> Ok "402"
          | `String "403" -> Ok "403"
          | `String "404" -> Ok "404"
          | `String "405" -> Ok "405"
          | `String "406" -> Ok "406"
          | `String "407" -> Ok "407"
          | `String "408" -> Ok "408"
          | `String "409" -> Ok "409"
          | `String "410" -> Ok "410"
          | `String "411" -> Ok "411"
          | `String "412" -> Ok "412"
          | `String "413" -> Ok "413"
          | `String "414" -> Ok "414"
          | `String "415" -> Ok "415"
          | `String "416" -> Ok "416"
          | `String "417" -> Ok "417"
          | `String "421" -> Ok "421"
          | `String "422" -> Ok "422"
          | `String "423" -> Ok "423"
          | `String "424" -> Ok "424"
          | `String "425" -> Ok "425"
          | `String "426" -> Ok "426"
          | `String "428" -> Ok "428"
          | `String "429" -> Ok "429"
          | `String "431" -> Ok "431"
          | `String "451" -> Ok "451"
          | `String "500" -> Ok "500"
          | `String "501" -> Ok "501"
          | `String "502" -> Ok "502"
          | `String "503" -> Ok "503"
          | `String "504" -> Ok "504"
          | `String "505" -> Ok "505"
          | `String "506" -> Ok "506"
          | `String "507" -> Ok "507"
          | `String "508" -> Ok "508"
          | `String "509" -> Ok "509"
          | `String "510" -> Ok "510"
          | `String "511" -> Ok "511"
          | `String "successful" -> Ok "successful"
          | `String "client_failure" -> Ok "client_failure"
          | `String "server_failure" -> Ok "server_failure"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
      end

      type t = Items.t list [@@deriving show, eq]
    end

    type t = {
      hook_id : int;
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
      status : Status.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/events"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("hook_id", Var (params.hook_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("status", Var (params.status, Option (Array String)));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdHooksHookIdEventsHookLogIdResend = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      hook_log_id : int;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end
    module Too_many_requests = struct end

    type t =
      [ `Created
      | `Not_found
      | `Unprocessable_entity
      | `Too_many_requests
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
        ("429", fun _ -> Ok `Too_many_requests);
      ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/events/{hook_log_id}/resend"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, Int));
           ("hook_id", Var (params.hook_id, Int));
           ("hook_log_id", Var (params.hook_log_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4ProjectsIdHooksHookIdTestTrigger = struct
  module Parameters = struct
    module Trigger = struct
      let t_of_yojson = function
        | `String "confidential_issues_events" -> Ok "confidential_issues_events"
        | `String "confidential_note_events" -> Ok "confidential_note_events"
        | `String "deployment_events" -> Ok "deployment_events"
        | `String "emoji_events" -> Ok "emoji_events"
        | `String "feature_flag_events" -> Ok "feature_flag_events"
        | `String "issues_events" -> Ok "issues_events"
        | `String "job_events" -> Ok "job_events"
        | `String "merge_requests_events" -> Ok "merge_requests_events"
        | `String "note_events" -> Ok "note_events"
        | `String "pipeline_events" -> Ok "pipeline_events"
        | `String "push_events" -> Ok "push_events"
        | `String "releases_events" -> Ok "releases_events"
        | `String "resource_access_token_events" -> Ok "resource_access_token_events"
        | `String "tag_push_events" -> Ok "tag_push_events"
        | `String "wiki_page_events" -> Ok "wiki_page_events"
        | `String "vulnerability_events" -> Ok "vulnerability_events"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      hook_id : int;
      id : int;
      trigger : Trigger.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Not_found = struct end
    module Unprocessable_entity = struct end
    module Too_many_requests = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Not_found
      | `Unprocessable_entity
      | `Too_many_requests
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
        ("422", fun _ -> Ok `Unprocessable_entity);
        ("429", fun _ -> Ok `Too_many_requests);
      ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/test/{trigger}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("hook_id", Var (params.hook_id, Int));
           ("trigger", Var (params.trigger, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4ProjectsIdHooksHookIdUrlVariablesKey = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : int;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/url_variables/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("hook_id", Var (params.hook_id, Int));
           ("key", Var (params.key, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4ProjectsIdHooksHookIdUrlVariablesKey = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      id : int;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PutApiV4ProjectsIdHooksHookIdUrlVariablesKey.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/projects/{id}/hooks/{hook_id}/url_variables/{key}"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("hook_id", Var (params.hook_id, Int));
           ("key", Var (params.key, String));
           ("id", Var (params.id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end
