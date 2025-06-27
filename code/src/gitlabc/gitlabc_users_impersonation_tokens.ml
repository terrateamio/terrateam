module PostApiV4UsersUserIdImpersonationTokens = struct
  module Parameters = struct
    type t = {
      postapiv4usersuseridimpersonationtokens :
        Gitlabc_components.PostApiV4UsersUserIdImpersonationTokens.t;
          [@key "postApiV4UsersUserIdImpersonationTokens"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{user_id}/impersonation_tokens"

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

module GetApiV4UsersUserIdImpersonationTokens = struct
  module Parameters = struct
    module State = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "active" -> Ok "active"
        | `String "inactive" -> Ok "inactive"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      page : int; [@default 1]
      per_page : int; [@default 20]
      state : State.t; [@default "all"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{user_id}/impersonation_tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("state", Var (params.state, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4UsersUserIdImpersonationTokensImpersonationTokenId = struct
  module Parameters = struct
    type t = {
      impersonation_token_id : int;
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/users/{user_id}/impersonation_tokens/{impersonation_token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("user_id", Var (params.user_id, Int));
           ("impersonation_token_id", Var (params.impersonation_token_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4UsersUserIdImpersonationTokensImpersonationTokenId = struct
  module Parameters = struct
    type t = {
      impersonation_token_id : int;
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{user_id}/impersonation_tokens/{impersonation_token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("user_id", Var (params.user_id, Int));
           ("impersonation_token_id", Var (params.impersonation_token_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
