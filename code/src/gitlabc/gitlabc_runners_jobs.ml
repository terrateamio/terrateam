module GetApiV4RunnersIdJobs = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "id" -> Ok "id"
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
      cursor : string option; [@default None]
      id : int;
      order_by : Order_by.t option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
      sort : Sort.t; [@default "desc"]
      status : Status.t option; [@default None]
      system_id : string option; [@default None]
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

  let url = "/api/v4/runners/{id}/jobs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("system_id", Var (params.system_id, Option String));
           ("status", Var (params.status, Option String));
           ("order_by", Var (params.order_by, Option String));
           ("sort", Var (params.sort, String));
           ("cursor", Var (params.cursor, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
