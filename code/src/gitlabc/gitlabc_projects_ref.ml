module PostApiV4ProjectsId_refRef_triggerPipeline = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4projectsid_refref_triggerpipeline :
        Gitlabc_components.PostApiV4ProjectsId_refRef_triggerPipeline.t;
          [@key "postApiV4ProjectsId(refRef)triggerPipeline"]
      ref_ : string; [@key "ref"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/projects/{id}/ref/{ref}/trigger/pipeline"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("ref", Var (params.ref_, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end
