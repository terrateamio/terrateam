module Root = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Root.t [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Api_overview.t
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

  let url = "/meta"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_octocat = struct
  module Parameters = struct
    type t = { s : string option [@default None] } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/octocat"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("s", Var (params.s, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_zen = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/zen"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
