module PostApiV4GroupsIdExport = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Too_many_requests = struct end
    module Service_unavailable = struct end

    type t =
      [ `Accepted
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Too_many_requests
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("202", fun _ -> Ok `Accepted);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("429", fun _ -> Ok `Too_many_requests);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/groups/{id}/export"

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

module GetApiV4GroupsIdExportDownload = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end
    module Service_unavailable = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/groups/{id}/export/download"

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
      `Get
end
