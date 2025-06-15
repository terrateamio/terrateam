module GetApiV4ProjectsIdPipelines = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "id" -> Ok "id"
        | `String "status" -> Ok "status"
        | `String "ref" -> Ok "ref"
        | `String "updated_at" -> Ok "updated_at"
        | `String "user_id" -> Ok "user_id"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Scope = struct
      let t_of_yojson = function
        | `String "running" -> Ok "running"
        | `String "pending" -> Ok "pending"
        | `String "finished" -> Ok "finished"
        | `String "branches" -> Ok "branches"
        | `String "tags" -> Ok "tags"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Source = struct
      let t_of_yojson = function
        | `String "unknown" -> Ok "unknown"
        | `String "push" -> Ok "push"
        | `String "web" -> Ok "web"
        | `String "trigger" -> Ok "trigger"
        | `String "schedule" -> Ok "schedule"
        | `String "api" -> Ok "api"
        | `String "external" -> Ok "external"
        | `String "pipeline" -> Ok "pipeline"
        | `String "chat" -> Ok "chat"
        | `String "webide" -> Ok "webide"
        | `String "merge_request_event" -> Ok "merge_request_event"
        | `String "external_pull_request_event" -> Ok "external_pull_request_event"
        | `String "parent_pipeline" -> Ok "parent_pipeline"
        | `String "ondemand_dast_scan" -> Ok "ondemand_dast_scan"
        | `String "ondemand_dast_validation" -> Ok "ondemand_dast_validation"
        | `String "security_orchestration_policy" -> Ok "security_orchestration_policy"
        | `String "container_registry_push" -> Ok "container_registry_push"
        | `String "duo_workflow" -> Ok "duo_workflow"
        | `String "pipeline_execution_policy_schedule" -> Ok "pipeline_execution_policy_schedule"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Status = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "waiting_for_resource" -> Ok "waiting_for_resource"
        | `String "preparing" -> Ok "preparing"
        | `String "waiting_for_callback" -> Ok "waiting_for_callback"
        | `String "pending" -> Ok "pending"
        | `String "running" -> Ok "running"
        | `String "success" -> Ok "success"
        | `String "failed" -> Ok "failed"
        | `String "canceling" -> Ok "canceling"
        | `String "canceled" -> Ok "canceled"
        | `String "skipped" -> Ok "skipped"
        | `String "manual" -> Ok "manual"
        | `String "scheduled" -> Ok "scheduled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      name : string option; [@default None]
      order_by : Order_by.t; [@default "id"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      ref_ : string option; [@default None] [@key "ref"]
      scope : Scope.t option; [@default None]
      sha : string option; [@default None]
      sort : Sort.t; [@default "desc"]
      source : Source.t option; [@default None]
      status : Status.t option; [@default None]
      updated_after : string option; [@default None]
      updated_before : string option; [@default None]
      username : string option; [@default None]
      yaml_errors : bool option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/api/v4/projects/{id}/pipelines"

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
           ("scope", Var (params.scope, Option String));
           ("status", Var (params.status, Option String));
           ("ref", Var (params.ref_, Option String));
           ("sha", Var (params.sha, Option String));
           ("yaml_errors", Var (params.yaml_errors, Option Bool));
           ("username", Var (params.username, Option String));
           ("updated_before", Var (params.updated_before, Option String));
           ("updated_after", Var (params.updated_after, Option String));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("source", Var (params.source, Option String));
           ("name", Var (params.name, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPipelinesLatest = struct
  module Parameters = struct
    type t = {
      id : string;
      ref_ : string option; [@default None] [@key "ref"]
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/projects/{id}/pipelines/latest"

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
         [ ("ref", Var (params.ref_, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4ProjectsIdPipelinesPipelineId = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4ProjectsIdPipelinesPipelineId = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPipelinesPipelineIdBridges = struct
  module Parameters = struct
    module Scope = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "waiting_for_resource" -> Ok "waiting_for_resource"
        | `String "preparing" -> Ok "preparing"
        | `String "waiting_for_callback" -> Ok "waiting_for_callback"
        | `String "pending" -> Ok "pending"
        | `String "running" -> Ok "running"
        | `String "success" -> Ok "success"
        | `String "failed" -> Ok "failed"
        | `String "canceling" -> Ok "canceling"
        | `String "canceled" -> Ok "canceled"
        | `String "skipped" -> Ok "skipped"
        | `String "manual" -> Ok "manual"
        | `String "scheduled" -> Ok "scheduled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      pipeline_id : int;
      scope : Scope.t option; [@default None]
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/bridges"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("scope", Var (params.scope, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4ProjectsIdPipelinesPipelineIdCancel = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/cancel"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPipelinesPipelineIdJobs = struct
  module Parameters = struct
    module Scope = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "waiting_for_resource" -> Ok "waiting_for_resource"
        | `String "preparing" -> Ok "preparing"
        | `String "waiting_for_callback" -> Ok "waiting_for_callback"
        | `String "pending" -> Ok "pending"
        | `String "running" -> Ok "running"
        | `String "success" -> Ok "success"
        | `String "failed" -> Ok "failed"
        | `String "canceling" -> Ok "canceling"
        | `String "canceled" -> Ok "canceled"
        | `String "skipped" -> Ok "skipped"
        | `String "manual" -> Ok "manual"
        | `String "scheduled" -> Ok "scheduled"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      include_retried : bool; [@default false]
      page : int; [@default 1]
      per_page : int; [@default 20]
      pipeline_id : int;
      scope : Scope.t option; [@default None]
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/jobs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("include_retried", Var (params.include_retried, Bool));
           ("scope", Var (params.scope, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PutApiV4ProjectsIdPipelinesPipelineIdMetadata = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
      putapiv4projectsidpipelinespipelineidmetadata :
        Gitlabc_components.PutApiV4ProjectsIdPipelinesPipelineIdMetadata.t;
          [@key "putApiV4ProjectsIdPipelinesPipelineIdMetadata"]
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

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/metadata"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module PostApiV4ProjectsIdPipelinesPipelineIdRetry = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/retry"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4ProjectsIdPipelinesPipelineIdTestReport = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/test_report"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPipelinesPipelineIdTestReportSummary = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/test_report_summary"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4ProjectsIdPipelinesPipelineIdVariables = struct
  module Parameters = struct
    type t = {
      id : string;
      pipeline_id : int;
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/projects/{id}/pipelines/{pipeline_id}/variables"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("pipeline_id", Var (params.pipeline_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
