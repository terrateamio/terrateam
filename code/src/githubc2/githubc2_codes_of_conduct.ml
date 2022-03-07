module Get_all_codes_of_conduct = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Code_of_conduct.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    type t =
      [ `OK of OK.t
      | `Not_modified
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
      ]
  end

  let url = "/codes_of_conduct"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_conduct_code = struct
  module Parameters = struct
    type t = { key : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Code_of_conduct.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/codes_of_conduct/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("key", Var (params.key, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Code_of_conduct.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/community/code_of_conduct"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
