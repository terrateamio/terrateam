module PostApiV4GroupsIdTransfer = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4groupsidtransfer : Gitlabc_components.PostApiV4GroupsIdTransfer.t;
          [@key "postApiV4GroupsIdTransfer"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/groups/{id}/transfer"

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
