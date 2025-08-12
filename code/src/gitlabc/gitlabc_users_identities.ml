module DeleteApiV4UsersIdIdentitiesProvider = struct
  module Parameters = struct
    type t = {
      id : int;
      provider : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/identities/{provider}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("provider", Var (params.provider, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end
