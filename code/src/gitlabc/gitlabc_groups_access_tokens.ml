module PostApiV4GroupsIdAccessTokens = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4groupsidaccesstokens : Gitlabc_components.PostApiV4GroupsIdAccessTokens.t;
          [@key "postApiV4GroupsIdAccessTokens"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/groups/{id}/access_tokens"

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

module GetApiV4GroupsIdAccessTokens = struct
  module Parameters = struct
    module State = struct
      let t_of_yojson = function
        | `String "active" -> Ok "active"
        | `String "inactive" -> Ok "inactive"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      id : string;
      state : State.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/groups/{id}/access_tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("state", Var (params.state, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4GroupsIdAccessTokensSelfRotate = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4groupsidaccesstokensselfrotate :
        Gitlabc_components.PostApiV4GroupsIdAccessTokensSelfRotate.t;
          [@key "postApiV4GroupsIdAccessTokensSelfRotate"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Method_not_allowed = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Method_not_allowed
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("405", fun _ -> Ok `Method_not_allowed);
      ]
  end

  let url = "/api/v4/groups/{id}/access_tokens/self/rotate"

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

module DeleteApiV4GroupsIdAccessTokensTokenId = struct
  module Parameters = struct
    type t = {
      id : string;
      token_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/access_tokens/{token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("token_id", Var (params.token_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4GroupsIdAccessTokensTokenId = struct
  module Parameters = struct
    type t = {
      id : string;
      token_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/groups/{id}/access_tokens/{token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("token_id", Var (params.token_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4GroupsIdAccessTokensTokenIdRotate = struct
  module Parameters = struct
    type t = {
      id : string;
      postapiv4groupsidaccesstokenstokenidrotate :
        Gitlabc_components.PostApiV4GroupsIdAccessTokensTokenIdRotate.t;
          [@key "postApiV4GroupsIdAccessTokensTokenIdRotate"]
      token_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/groups/{id}/access_tokens/{token_id}/rotate"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("token_id", Var (params.token_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end
