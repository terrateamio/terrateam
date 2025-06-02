module PostApiV4ProjectsIdHousekeeping = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsidhousekeeping : Gitlabc_components.PostApiV4ProjectsIdHousekeeping.t;
          [@key "postApiV4ProjectsIdHousekeeping"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Conflict = struct end

    type t =
      [ `Created
      | `Unauthorized
      | `Forbidden
      | `Conflict
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("409", fun _ -> Ok `Conflict);
      ]
  end

  let url = "/api/v4/projects/{id}/housekeeping"

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
