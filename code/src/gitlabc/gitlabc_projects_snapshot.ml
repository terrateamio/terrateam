module GetApiV4ProjectsIdSnapshot = struct
  module Parameters = struct
    type t = {
      id : int;
      wiki : bool option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end

    type t =
      [ `OK
      | `Unauthorized
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized) ]
  end

  let url = "/api/v4/projects/{id}/snapshot"

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
         [ ("wiki", Var (params.wiki, Option Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end
