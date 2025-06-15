module PostApiV4UsersUserIdPersonalAccessTokens = struct
  module Parameters = struct
    type t = {
      postapiv4usersuseridpersonalaccesstokens :
        Gitlabc_components.PostApiV4UsersUserIdPersonalAccessTokens.t;
          [@key "postApiV4UsersUserIdPersonalAccessTokens"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{user_id}/personal_access_tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end
