module Create = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        base : string;
        body : string option; [@default None]
        draft : bool option; [@default None]
        head : string;
        issue : int option; [@default None]
        maintainer_can_modify : bool option; [@default None]
        title : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Pull_request.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List = struct
  module Parameters = struct
    module Direction = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "updated" -> Ok "updated"
        | `String "popularity" -> Ok "popularity"
        | `String "long-running" -> Ok "long-running"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module State = struct
      let t_of_yojson = function
        | `String "open" -> Ok "open"
        | `String "closed" -> Ok "closed"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      base : string option; [@default None]
      direction : Direction.t option; [@default None]
      head : string option; [@default None]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
      sort : Sort.t; [@default "created"]
      state : State.t; [@default "open"]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_simple.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("state", Var (params.state, String));
          ("head", Var (params.head, Option String));
          ("base", Var (params.base, Option String));
          ("sort", Var (params.sort, String));
          ("direction", Var (params.direction, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_review_comments_for_repo = struct
  module Parameters = struct
    module Direction = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "updated" -> Ok "updated"
        | `String "created_at" -> Ok "created_at"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      direction : Direction.t option; [@default None]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
      since : string option; [@default None]
      sort : Sort.t option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review_comment.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/pulls/comments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("sort", Var (params.sort, Option String));
          ("direction", Var (params.direction, Option String));
          ("since", Var (params.since, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_review_comment = struct
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
      type t = { body : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review_comment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/pulls/comments/{comment_id}"

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
      `Patch
end

module Delete_review_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/comments/{comment_id}"

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
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_review_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review_comment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/comments/{comment_id}"

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
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Update = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module State = struct
        let t_of_yojson = function
          | `String "open" -> Ok "open"
          | `String "closed" -> Ok "closed"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        base : string option; [@default None]
        body : string option; [@default None]
        maintainer_can_modify : bool option; [@default None]
        state : State.t option; [@default None]
        title : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Get = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_review_comment = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Side = struct
        let t_of_yojson = function
          | `String "LEFT" -> Ok "LEFT"
          | `String "RIGHT" -> Ok "RIGHT"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Start_side = struct
        let t_of_yojson = function
          | `String "LEFT" -> Ok "LEFT"
          | `String "RIGHT" -> Ok "RIGHT"
          | `String "side" -> Ok "side"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        body : string;
        commit_id : string option; [@default None]
        in_reply_to : int option; [@default None]
        line : int option; [@default None]
        path : string option; [@default None]
        position : int option; [@default None]
        side : Side.t option; [@default None]
        start_line : int option; [@default None]
        start_side : Start_side.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Pull_request_review_comment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/comments"

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
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_review_comments = struct
  module Parameters = struct
    module Direction = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "updated" -> Ok "updated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      direction : Direction.t option; [@default None]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      pull_number : int;
      repo : string;
      since : string option; [@default None]
      sort : Sort.t; [@default "created"]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review_comment.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/comments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("sort", Var (params.sort, String));
          ("direction", Var (params.direction, Option String));
          ("since", Var (params.since, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Create_reply_for_review_comment = struct
  module Parameters = struct
    type t = {
      comment_id : int;
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { body : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Pull_request_review_comment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/comments/{comment_id}/replies"

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
          ("pull_number", Var (params.pull_number, Int));
          ("comment_id", Var (params.comment_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_commits = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Commit.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_files = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Diff_entry.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Internal_server_error = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/files"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Merge = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Merge_method = struct
        let t_of_yojson = function
          | `String "merge" -> Ok "merge"
          | `String "squash" -> Ok "squash"
          | `String "rebase" -> Ok "rebase"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        commit_message : string option; [@default None]
        commit_title : string option; [@default None]
        merge_method : Merge_method.t option; [@default None]
        sha : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_merge_result.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Method_not_allowed = struct
      module Primary = struct
        type t = {
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Conflict = struct
      module Primary = struct
        type t = {
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("405", Openapi.of_json_body (fun v -> `Method_not_allowed v) Method_not_allowed.of_yojson);
        ("409", Openapi.of_json_body (fun v -> `Conflict v) Conflict.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/merge"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Check_if_merged = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_found = struct end

    let t = [ ("204", fun _ -> Ok `No_content); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/merge"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_requested_reviewers = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Reviewers = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Team_reviewers = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        reviewers : Reviewers.t;
        team_reviewers : Team_reviewers.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/requested_reviewers"

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
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Request_reviewers = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Reviewers = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        module Team_reviewers = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          reviewers : Reviewers.t;
          team_reviewers : Team_reviewers.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module V1 = struct
      module Primary = struct
        module Reviewers = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        module Team_reviewers = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          reviewers : Reviewers.t option; [@default None]
          team_reviewers : Team_reviewers.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t =
      | V0 of V0.t
      | V1 of V1.t
    [@@deriving show]

    let of_yojson =
      Json_schema.any_of
        (let open CCResult in
        [
          (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
          (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
        ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
      | V1 v -> V1.to_yojson v
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Pull_request_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/requested_reviewers"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_requested_reviewers = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review_request.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/requested_reviewers"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Create_review = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Comments = struct
        module Items = struct
          module Primary = struct
            type t = {
              body : string;
              line : int option; [@default None]
              path : string;
              position : int option; [@default None]
              side : string option; [@default None]
              start_line : int option; [@default None]
              start_side : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Event = struct
        let t_of_yojson = function
          | `String "APPROVE" -> Ok "APPROVE"
          | `String "REQUEST_CHANGES" -> Ok "REQUEST_CHANGES"
          | `String "COMMENT" -> Ok "COMMENT"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        body : string option; [@default None]
        comments : Comments.t option; [@default None]
        commit_id : string option; [@default None]
        event : Event.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/reviews"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_reviews = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/reviews"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_pending_review = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
      review_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/reviews/{review_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
          ("review_id", Var (params.review_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Update_review = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
      review_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { body : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/reviews/{review_id}"

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
          ("pull_number", Var (params.pull_number, Int));
          ("review_id", Var (params.review_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_review = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
      review_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/reviews/{review_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
          ("review_id", Var (params.review_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_comments_for_review = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      pull_number : int;
      repo : string;
      review_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Review_comment.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/reviews/{review_id}/comments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
          ("review_id", Var (params.review_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Dismiss_review = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
      review_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        event : string option; [@default None]
        message : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/reviews/{review_id}/dismissals"

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
          ("pull_number", Var (params.pull_number, Int));
          ("review_id", Var (params.review_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Submit_review = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
      review_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Event = struct
        let t_of_yojson = function
          | `String "APPROVE" -> Ok "APPROVE"
          | `String "REQUEST_CHANGES" -> Ok "REQUEST_CHANGES"
          | `String "COMMENT" -> Ok "COMMENT"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        body : string option; [@default None]
        event : Event.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_review.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/reviews/{review_id}/events"

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
          ("pull_number", Var (params.pull_number, Int));
          ("review_id", Var (params.review_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Update_branch = struct
  module Parameters = struct
    type t = {
      owner : string;
      pull_number : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { expected_head_sha : string option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Accepted = struct
      module Primary = struct
        type t = {
          message : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pulls/{pull_number}/update-branch"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("pull_number", Var (params.pull_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end
