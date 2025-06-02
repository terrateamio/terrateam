module PostApiV4ProjectsIdStatusesSha = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidstatusessha : Gitlabc_components.PostApiV4ProjectsIdStatusesSha.t;
          [@key "postApiV4ProjectsIdStatusesSha"]
      sha : string;
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

  let url = "/api/v4/projects/{id}/statuses/{sha}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("sha", Var (params.sha, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end
