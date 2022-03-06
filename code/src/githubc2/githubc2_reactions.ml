module Create_for_team_discussion_comment_in_org = struct
  module Parameters = struct
    type t = {
      comment_number : int;
      discussion_number : int;
      org : string;
      team_slug : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Content = struct
        let t_of_yojson = function
          | `String "+1" -> Ok "+1"
          | `String "-1" -> Ok "-1"
          | `String "laugh" -> Ok "laugh"
          | `String "confused" -> Ok "confused"
          | `String "heart" -> Ok "heart"
          | `String "hooray" -> Ok "hooray"
          | `String "rocket" -> Ok "rocket"
          | `String "eyes" -> Ok "eyes"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { content : Content.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Created = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Created of Created.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
      ]
  end

  let url =
    "/orgs/{org}/teams/{team_slug}/discussions/{discussion_number}/comments/{comment_number}/reactions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("team_slug", Var (params.team_slug, String));
          ("discussion_number", Var (params.discussion_number, Int));
          ("comment_number", Var (params.comment_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_team_discussion_comment_in_org = struct
  module Parameters = struct
    module Content = struct
      let t_of_yojson = function
        | `String "+1" -> Ok "+1"
        | `String "-1" -> Ok "-1"
        | `String "laugh" -> Ok "laugh"
        | `String "confused" -> Ok "confused"
        | `String "heart" -> Ok "heart"
        | `String "hooray" -> Ok "hooray"
        | `String "rocket" -> Ok "rocket"
        | `String "eyes" -> Ok "eyes"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      comment_number : int;
      content : Content.t option; [@default None]
      discussion_number : int;
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      team_slug : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url =
    "/orgs/{org}/teams/{team_slug}/discussions/{discussion_number}/comments/{comment_number}/reactions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("team_slug", Var (params.team_slug, String));
          ("discussion_number", Var (params.discussion_number, Int));
          ("comment_number", Var (params.comment_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("content", Var (params.content, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_for_team_discussion_comment = struct
  module Parameters = struct
    type t = {
      comment_number : int;
      discussion_number : int;
      org : string;
      reaction_id : int;
      team_slug : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url =
    "/orgs/{org}/teams/{team_slug}/discussions/{discussion_number}/comments/{comment_number}/reactions/{reaction_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("team_slug", Var (params.team_slug, String));
          ("discussion_number", Var (params.discussion_number, Int));
          ("comment_number", Var (params.comment_number, Int));
          ("reaction_id", Var (params.reaction_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_for_team_discussion_in_org = struct
  module Parameters = struct
    type t = {
      discussion_number : int;
      org : string;
      team_slug : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Content = struct
        let t_of_yojson = function
          | `String "+1" -> Ok "+1"
          | `String "-1" -> Ok "-1"
          | `String "laugh" -> Ok "laugh"
          | `String "confused" -> Ok "confused"
          | `String "heart" -> Ok "heart"
          | `String "hooray" -> Ok "hooray"
          | `String "rocket" -> Ok "rocket"
          | `String "eyes" -> Ok "eyes"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { content : Content.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Created = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Created of Created.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
      ]
  end

  let url = "/orgs/{org}/teams/{team_slug}/discussions/{discussion_number}/reactions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("team_slug", Var (params.team_slug, String));
          ("discussion_number", Var (params.discussion_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_team_discussion_in_org = struct
  module Parameters = struct
    module Content = struct
      let t_of_yojson = function
        | `String "+1" -> Ok "+1"
        | `String "-1" -> Ok "-1"
        | `String "laugh" -> Ok "laugh"
        | `String "confused" -> Ok "confused"
        | `String "heart" -> Ok "heart"
        | `String "hooray" -> Ok "hooray"
        | `String "rocket" -> Ok "rocket"
        | `String "eyes" -> Ok "eyes"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      content : Content.t option; [@default None]
      discussion_number : int;
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      team_slug : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/teams/{team_slug}/discussions/{discussion_number}/reactions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("team_slug", Var (params.team_slug, String));
          ("discussion_number", Var (params.discussion_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("content", Var (params.content, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_for_team_discussion = struct
  module Parameters = struct
    type t = {
      discussion_number : int;
      org : string;
      reaction_id : int;
      team_slug : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/teams/{team_slug}/discussions/{discussion_number}/reactions/{reaction_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("team_slug", Var (params.team_slug, String));
          ("discussion_number", Var (params.discussion_number, Int));
          ("reaction_id", Var (params.reaction_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Delete_legacy = struct
  module Parameters = struct
    type t = { reaction_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Gone = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `No_content
      | `Not_modified
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Gone of Gone.t
      ]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("410", Openapi.of_json_body (fun v -> `Gone v) Gone.of_yojson);
      ]
  end

  let url = "/reactions/{reaction_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("reaction_id", Var (params.reaction_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_for_commit_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Content = struct
        let t_of_yojson = function
          | `String "+1" -> Ok "+1"
          | `String "-1" -> Ok "-1"
          | `String "laugh" -> Ok "laugh"
          | `String "confused" -> Ok "confused"
          | `String "heart" -> Ok "heart"
          | `String "hooray" -> Ok "hooray"
          | `String "rocket" -> Ok "rocket"
          | `String "eyes" -> Ok "eyes"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { content : Content.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Created = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unsupported_media_type = struct
      module Primary = struct
        type t = {
          documentation_url : string;
          message : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Created of Created.t
      | `Unsupported_media_type of Unsupported_media_type.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/comments/{comment_id}/reactions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("comment_id", Var (params.comment_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_commit_comment = struct
  module Parameters = struct
    module Content = struct
      let t_of_yojson = function
        | `String "+1" -> Ok "+1"
        | `String "-1" -> Ok "-1"
        | `String "laugh" -> Ok "laugh"
        | `String "confused" -> Ok "confused"
        | `String "heart" -> Ok "heart"
        | `String "hooray" -> Ok "hooray"
        | `String "rocket" -> Ok "rocket"
        | `String "eyes" -> Ok "eyes"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      comment_id : int;
      content : Content.t option; [@default None]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/comments/{comment_id}/reactions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("comment_id", Var (params.comment_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("content", Var (params.content, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_for_commit_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      owner : string;
      reaction_id : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/comments/{comment_id}/reactions/{reaction_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("comment_id", Var (params.comment_id, Int));
          ("reaction_id", Var (params.reaction_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_for_issue_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Content = struct
        let t_of_yojson = function
          | `String "+1" -> Ok "+1"
          | `String "-1" -> Ok "-1"
          | `String "laugh" -> Ok "laugh"
          | `String "confused" -> Ok "confused"
          | `String "heart" -> Ok "heart"
          | `String "hooray" -> Ok "hooray"
          | `String "rocket" -> Ok "rocket"
          | `String "eyes" -> Ok "eyes"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { content : Content.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Created = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Created of Created.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/issues/comments/{comment_id}/reactions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("comment_id", Var (params.comment_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_issue_comment = struct
  module Parameters = struct
    module Content = struct
      let t_of_yojson = function
        | `String "+1" -> Ok "+1"
        | `String "-1" -> Ok "-1"
        | `String "laugh" -> Ok "laugh"
        | `String "confused" -> Ok "confused"
        | `String "heart" -> Ok "heart"
        | `String "hooray" -> Ok "hooray"
        | `String "rocket" -> Ok "rocket"
        | `String "eyes" -> Ok "eyes"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      comment_id : int;
      content : Content.t option; [@default None]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/issues/comments/{comment_id}/reactions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("comment_id", Var (params.comment_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("content", Var (params.content, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_for_issue_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      owner : string;
      reaction_id : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/issues/comments/{comment_id}/reactions/{reaction_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("comment_id", Var (params.comment_id, Int));
          ("reaction_id", Var (params.reaction_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_for_issue = struct
  module Parameters = struct
    type t = {
      issue_number : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Content = struct
        let t_of_yojson = function
          | `String "+1" -> Ok "+1"
          | `String "-1" -> Ok "-1"
          | `String "laugh" -> Ok "laugh"
          | `String "confused" -> Ok "confused"
          | `String "heart" -> Ok "heart"
          | `String "hooray" -> Ok "hooray"
          | `String "rocket" -> Ok "rocket"
          | `String "eyes" -> Ok "eyes"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { content : Content.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Created = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Created of Created.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/issues/{issue_number}/reactions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("issue_number", Var (params.issue_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_issue = struct
  module Parameters = struct
    module Content = struct
      let t_of_yojson = function
        | `String "+1" -> Ok "+1"
        | `String "-1" -> Ok "-1"
        | `String "laugh" -> Ok "laugh"
        | `String "confused" -> Ok "confused"
        | `String "heart" -> Ok "heart"
        | `String "hooray" -> Ok "hooray"
        | `String "rocket" -> Ok "rocket"
        | `String "eyes" -> Ok "eyes"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      content : Content.t option; [@default None]
      issue_number : int;
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Gone = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      | `Gone of Gone.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("410", Openapi.of_json_body (fun v -> `Gone v) Gone.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/issues/{issue_number}/reactions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("issue_number", Var (params.issue_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("content", Var (params.content, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_for_issue = struct
  module Parameters = struct
    type t = {
      issue_number : int;
      owner : string;
      reaction_id : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/issues/{issue_number}/reactions/{reaction_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("issue_number", Var (params.issue_number, Int));
          ("reaction_id", Var (params.reaction_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_for_pull_request_review_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Content = struct
        let t_of_yojson = function
          | `String "+1" -> Ok "+1"
          | `String "-1" -> Ok "-1"
          | `String "laugh" -> Ok "laugh"
          | `String "confused" -> Ok "confused"
          | `String "heart" -> Ok "heart"
          | `String "hooray" -> Ok "hooray"
          | `String "rocket" -> Ok "rocket"
          | `String "eyes" -> Ok "eyes"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { content : Content.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Created = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Created of Created.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/comments/{comment_id}/reactions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("comment_id", Var (params.comment_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_pull_request_review_comment = struct
  module Parameters = struct
    module Content = struct
      let t_of_yojson = function
        | `String "+1" -> Ok "+1"
        | `String "-1" -> Ok "-1"
        | `String "laugh" -> Ok "laugh"
        | `String "confused" -> Ok "confused"
        | `String "heart" -> Ok "heart"
        | `String "hooray" -> Ok "hooray"
        | `String "rocket" -> Ok "rocket"
        | `String "eyes" -> Ok "eyes"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      comment_id : int;
      content : Content.t option; [@default None]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/comments/{comment_id}/reactions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("comment_id", Var (params.comment_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("content", Var (params.content, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_for_pull_request_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      owner : string;
      reaction_id : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/pulls/comments/{comment_id}/reactions/{reaction_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("comment_id", Var (params.comment_id, Int));
          ("reaction_id", Var (params.reaction_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_for_release = struct
  module Parameters = struct
    type t = {
      owner : string;
      release_id : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Content = struct
        let t_of_yojson = function
          | `String "+1" -> Ok "+1"
          | `String "laugh" -> Ok "laugh"
          | `String "heart" -> Ok "heart"
          | `String "hooray" -> Ok "hooray"
          | `String "rocket" -> Ok "rocket"
          | `String "eyes" -> Ok "eyes"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { content : Content.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Created = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Created of Created.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/releases/{release_id}/reactions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("release_id", Var (params.release_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Create_for_team_discussion_comment_legacy = struct
  module Parameters = struct
    type t = {
      comment_number : int;
      discussion_number : int;
      team_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Content = struct
        let t_of_yojson = function
          | `String "+1" -> Ok "+1"
          | `String "-1" -> Ok "-1"
          | `String "laugh" -> Ok "laugh"
          | `String "confused" -> Ok "confused"
          | `String "heart" -> Ok "heart"
          | `String "hooray" -> Ok "hooray"
          | `String "rocket" -> Ok "rocket"
          | `String "eyes" -> Ok "eyes"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { content : Content.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/teams/{team_id}/discussions/{discussion_number}/comments/{comment_number}/reactions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("team_id", Var (params.team_id, Int));
          ("discussion_number", Var (params.discussion_number, Int));
          ("comment_number", Var (params.comment_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_team_discussion_comment_legacy = struct
  module Parameters = struct
    module Content = struct
      let t_of_yojson = function
        | `String "+1" -> Ok "+1"
        | `String "-1" -> Ok "-1"
        | `String "laugh" -> Ok "laugh"
        | `String "confused" -> Ok "confused"
        | `String "heart" -> Ok "heart"
        | `String "hooray" -> Ok "hooray"
        | `String "rocket" -> Ok "rocket"
        | `String "eyes" -> Ok "eyes"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      comment_number : int;
      content : Content.t option; [@default None]
      discussion_number : int;
      page : int; [@default 1]
      per_page : int; [@default 30]
      team_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/teams/{team_id}/discussions/{discussion_number}/comments/{comment_number}/reactions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("team_id", Var (params.team_id, Int));
          ("discussion_number", Var (params.discussion_number, Int));
          ("comment_number", Var (params.comment_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("content", Var (params.content, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Create_for_team_discussion_legacy = struct
  module Parameters = struct
    type t = {
      discussion_number : int;
      team_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Content = struct
        let t_of_yojson = function
          | `String "+1" -> Ok "+1"
          | `String "-1" -> Ok "-1"
          | `String "laugh" -> Ok "laugh"
          | `String "confused" -> Ok "confused"
          | `String "heart" -> Ok "heart"
          | `String "hooray" -> Ok "hooray"
          | `String "rocket" -> Ok "rocket"
          | `String "eyes" -> Ok "eyes"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { content : Content.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Reaction.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/teams/{team_id}/discussions/{discussion_number}/reactions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("team_id", Var (params.team_id, Int));
          ("discussion_number", Var (params.discussion_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_team_discussion_legacy = struct
  module Parameters = struct
    module Content = struct
      let t_of_yojson = function
        | `String "+1" -> Ok "+1"
        | `String "-1" -> Ok "-1"
        | `String "laugh" -> Ok "laugh"
        | `String "confused" -> Ok "confused"
        | `String "heart" -> Ok "heart"
        | `String "hooray" -> Ok "hooray"
        | `String "rocket" -> Ok "rocket"
        | `String "eyes" -> Ok "eyes"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      content : Content.t option; [@default None]
      discussion_number : int;
      page : int; [@default 1]
      per_page : int; [@default 30]
      team_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Reaction.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/teams/{team_id}/discussions/{discussion_number}/reactions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("team_id", Var (params.team_id, Int));
          ("discussion_number", Var (params.discussion_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("content", Var (params.content, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end
