module GetApiV4GroupsIdAuditEvents = struct
  module Parameters = struct
    type t = {
      created_after : string option; [@default None]
      created_before : string option; [@default None]
      id : int;
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

  let url = "/api/v4/groups/{id}/audit_events"

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
           ("created_after", Var (params.created_after, Option String));
           ("created_before", Var (params.created_before, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdAuditEventsAuditEventId = struct
  module Parameters = struct
    type t = {
      audit_event_id : int;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/groups/{id}/audit_events/{audit_event_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("audit_event_id", Var (params.audit_event_id, Int)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
