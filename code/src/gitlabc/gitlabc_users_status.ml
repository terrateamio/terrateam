module GetApiV4UsersUserIdStatus = struct
  module Parameters = struct
    type t = { user_id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{user_id}/status"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
