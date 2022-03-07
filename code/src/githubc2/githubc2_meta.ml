module Root = struct
  module Parameters = struct end

  module Responses = struct
    module OK = struct
      module Primary = struct
        type t = {
          authorizations_url : string;
          code_search_url : string;
          commit_search_url : string;
          current_user_authorizations_html_url : string;
          current_user_repositories_url : string;
          current_user_url : string;
          emails_url : string;
          emojis_url : string;
          events_url : string;
          feeds_url : string;
          followers_url : string;
          following_url : string;
          gists_url : string;
          hub_url : string;
          issue_search_url : string;
          issues_url : string;
          keys_url : string;
          label_search_url : string;
          notifications_url : string;
          organization_repositories_url : string;
          organization_teams_url : string;
          organization_url : string;
          public_gists_url : string;
          rate_limit_url : string;
          repository_search_url : string;
          repository_url : string;
          starred_gists_url : string;
          starred_url : string;
          topic_search_url : string option; [@default None]
          user_organizations_url : string;
          user_repositories_url : string;
          user_search_url : string;
          user_url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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
