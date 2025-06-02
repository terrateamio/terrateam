module PostApiV4GroupsIdShare = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4groupsidshare : Gitlabc_components.PostApiV4GroupsIdShare.t;
          [@key "postApiV4GroupsIdShare"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/groups/{id}/share"

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

module DeleteApiV4GroupsIdShareGroupId = struct
  module Parameters = struct
    type t = {
      group_id : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/groups/{id}/share/{group_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("group_id", Var (params.group_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end
