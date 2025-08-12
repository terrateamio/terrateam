module GetApiV4Version = struct
  module Parameters = struct end

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

  let url = "/api/v4/version"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
