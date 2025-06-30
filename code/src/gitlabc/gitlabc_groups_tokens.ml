module PostApiV4GroupsIdTokensRevoke = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4groupsidtokensrevoke : Gitlabc_components.PostApiV4GroupsIdTokensRevoke.t;
          [@key "postApiV4GroupsIdTokensRevoke"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/groups/{id}/tokens/revoke"

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
