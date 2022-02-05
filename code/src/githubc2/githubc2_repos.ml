module Create_in_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Visibility = struct
        let t_of_yojson = function
          | `String "public" -> Ok "public"
          | `String "private" -> Ok "private"
          | `String "visibility" -> Ok "visibility"
          | `String "internal" -> Ok "internal"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        allow_auto_merge : bool; [@default false]
        allow_merge_commit : bool; [@default true]
        allow_rebase_merge : bool; [@default true]
        allow_squash_merge : bool; [@default true]
        auto_init : bool; [@default false]
        delete_branch_on_merge : bool; [@default false]
        description : string option; [@default None]
        gitignore_template : string option; [@default None]
        has_issues : bool; [@default true]
        has_projects : bool; [@default true]
        has_wiki : bool; [@default true]
        homepage : string option; [@default None]
        is_template : bool; [@default false]
        license_template : string option; [@default None]
        name : string;
        private_ : bool; [@default false]
        team_id : int option; [@default None]
        visibility : Visibility.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Repository.t
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

  let url = "/orgs/{org}/repos"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_org = struct
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
        | `String "pushed" -> Ok "pushed"
        | `String "full_name" -> Ok "full_name"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Type = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "public" -> Ok "public"
        | `String "private" -> Ok "private"
        | `String "forks" -> Ok "forks"
        | `String "sources" -> Ok "sources"
        | `String "member" -> Ok "member"
        | `String "internal" -> Ok "internal"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      direction : Direction.t option; [@default None]
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      sort : Sort.t; [@default "created"]
      type_ : Type.t option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Minimal_repository.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/repos"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("type", Var (params.type_, Option String));
          ("sort", Var (params.sort, String));
          ("direction", Var (params.direction, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Security_and_analysis = struct
        module Primary = struct
          module Advanced_security = struct
            module Primary = struct
              type t = { status : string option [@default None] }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Secret_scanning = struct
            module Primary = struct
              type t = { status : string option [@default None] }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            advanced_security : Advanced_security.t option; [@default None]
            secret_scanning : Secret_scanning.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Visibility = struct
        let t_of_yojson = function
          | `String "public" -> Ok "public"
          | `String "private" -> Ok "private"
          | `String "visibility" -> Ok "visibility"
          | `String "internal" -> Ok "internal"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        allow_auto_merge : bool; [@default false]
        allow_forking : bool; [@default false]
        allow_merge_commit : bool; [@default true]
        allow_rebase_merge : bool; [@default true]
        allow_squash_merge : bool; [@default true]
        archived : bool; [@default false]
        default_branch : string option; [@default None]
        delete_branch_on_merge : bool; [@default false]
        description : string option; [@default None]
        has_issues : bool; [@default true]
        has_projects : bool; [@default true]
        has_wiki : bool; [@default true]
        homepage : string option; [@default None]
        is_template : bool; [@default false]
        name : string option; [@default None]
        private_ : bool; [@default false]
        security_and_analysis : Security_and_analysis.t option; [@default None]
        visibility : Visibility.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Full_repository.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Temporary_redirect = struct
      type t = Githubc2_components.Basic_error.t
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
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("307", Openapi.of_json_body (fun v -> `Temporary_redirect v) Temporary_redirect.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("owner", Var (params.owner, String)); ("repo", Var (params.repo, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    module Temporary_redirect = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      module Primary = struct
        type t = {
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("307", Openapi.of_json_body (fun v -> `Temporary_redirect v) Temporary_redirect.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}"

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
      `Delete
end

module Get = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Full_repository.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Moved_permanently = struct
      type t = Githubc2_components.Basic_error.t
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

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("301", Openapi.of_json_body (fun v -> `Moved_permanently v) Moved_permanently.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}"

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

module Create_autolink = struct
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
        key_prefix : string;
        url_template : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Autolink.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/autolinks"

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

module List_autolinks = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Autolink.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/autolinks"

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
        [ ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_autolink = struct
  module Parameters = struct
    type t = {
      autolink_id : int;
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

  let url = "/repos/{owner}/{repo}/autolinks/{autolink_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("autolink_id", Var (params.autolink_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_autolink = struct
  module Parameters = struct
    type t = {
      autolink_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Autolink.t
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

  let url = "/repos/{owner}/{repo}/autolinks/{autolink_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("autolink_id", Var (params.autolink_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Disable_automated_security_fixes = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/automated-security-fixes"

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
      `Delete
end

module Enable_automated_security_fixes = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/automated-security-fixes"

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
      `Put
end

module List_branches = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      protected : bool option; [@default None]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Short_branch.t list
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

  let url = "/repos/{owner}/{repo}/branches"

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
          ("protected", Var (params.protected, Option Bool));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_branch = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Branch_with_protection.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Moved_permanently = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
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

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("301", Openapi.of_json_body (fun v -> `Moved_permanently v) Moved_permanently.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_branch_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Update_branch_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Required_pull_request_reviews = struct
        module Primary = struct
          module Dismissal_restrictions = struct
            module Primary = struct
              module Teams = struct
                type t = string list [@@deriving yojson { strict = false; meta = true }, show]
              end

              module Users = struct
                type t = string list [@@deriving yojson { strict = false; meta = true }, show]
              end

              type t = {
                teams : Teams.t option; [@default None]
                users : Users.t option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            dismiss_stale_reviews : bool option; [@default None]
            dismissal_restrictions : Dismissal_restrictions.t option; [@default None]
            require_code_owner_reviews : bool option; [@default None]
            required_approving_review_count : int option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Required_status_checks = struct
        module Primary = struct
          module Contexts = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = {
            contexts : Contexts.t;
            strict : bool;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Restrictions = struct
        module Primary = struct
          module Apps = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show]
          end

          module Teams = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show]
          end

          module Users = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = {
            apps : Apps.t option; [@default None]
            teams : Teams.t;
            users : Users.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        allow_deletions : bool option; [@default None]
        allow_force_pushes : bool option; [@default None]
        enforce_admins : bool option;
        required_conversation_resolution : bool option; [@default None]
        required_linear_history : bool option; [@default None]
        required_pull_request_reviews : Required_pull_request_reviews.t option;
        required_status_checks : Required_status_checks.t option;
        restrictions : Restrictions.t option;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Protected_branch.t
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection"

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
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_branch_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Branch_protection.t
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_admin_branch_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/enforce_admins"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Set_admin_branch_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Protected_branch_admin_enforced.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/enforce_admins"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Get_admin_branch_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Protected_branch_admin_enforced.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/enforce_admins"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Update_pull_request_review_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Dismissal_restrictions = struct
        module Primary = struct
          module Teams = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show]
          end

          module Users = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = {
            teams : Teams.t option; [@default None]
            users : Users.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        dismiss_stale_reviews : bool option; [@default None]
        dismissal_restrictions : Dismissal_restrictions.t option; [@default None]
        require_code_owner_reviews : bool option; [@default None]
        required_approving_review_count : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Protected_branch_pull_request_review.t
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_pull_request_reviews"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_pull_request_review_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_pull_request_reviews"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_pull_request_review_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Protected_branch_pull_request_review.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_pull_request_reviews"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_commit_signature_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_signatures"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_commit_signature_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Protected_branch_admin_enforced.t
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_signatures"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Get_commit_signature_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Protected_branch_admin_enforced.t
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_signatures"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Update_status_check_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Contexts = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        contexts : Contexts.t option; [@default None]
        strict : bool option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Status_check_policy.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
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
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Remove_status_check_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_status_checks_protection = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Status_check_policy.t
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_status_check_contexts = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Contexts = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { contexts : Contexts.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = string list [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
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
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks/contexts"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_status_check_contexts = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Contexts = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { contexts : Contexts.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = string list [@@deriving yojson { strict = false; meta = false }, show]
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
      type t = Githubc2_components.Validation_error.t
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks/contexts"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Set_status_check_contexts = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Contexts = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { contexts : Contexts.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = string list [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
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
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks/contexts"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_all_status_check_contexts = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = string list [@@deriving yojson { strict = false; meta = false }, show]
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks/contexts"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Branch_restriction_policy.t
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_app_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Apps = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { apps : Apps.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Integration.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/apps"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_app_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Apps = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { apps : Apps.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Integration.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/apps"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Set_app_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Apps = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { apps : Apps.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Integration.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/apps"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_apps_with_access_to_protected_branch = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Integration.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/apps"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_team_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Teams = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { teams : Teams.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Team.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/teams"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_team_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Teams = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { teams : Teams.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Team.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/teams"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Set_team_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Teams = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { teams : Teams.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Team.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/teams"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_teams_with_access_to_protected_branch = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Team.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/teams"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_user_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Users = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { users : Users.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Simple_user.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/users"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_user_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Users = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { users : Users.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Simple_user.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/users"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Set_user_access_restrictions = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Users = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { users : Users.t } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = V0 of V0.t [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [ (fun v -> map (fun v -> V0 v) (V0.of_yojson v)) ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Simple_user.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/users"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_users_with_access_to_protected_branch = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Simple_user.t list
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

  let url = "/repos/{owner}/{repo}/branches/{branch}/protection/restrictions/users"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Rename_branch = struct
  module Parameters = struct
    type t = {
      branch : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { new_name : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Branch_with_protection.t
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
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/branches/{branch}/rename"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("branch", Var (params.branch, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_collaborators = struct
  module Parameters = struct
    module Affiliation = struct
      let t_of_yojson = function
        | `String "outside" -> Ok "outside"
        | `String "direct" -> Ok "direct"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      affiliation : Affiliation.t; [@default "all"]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Collaborator.t list
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

  let url = "/repos/{owner}/{repo}/collaborators"

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
          ("affiliation", Var (params.affiliation, String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_collaborator = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      username : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/collaborators/{username}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("username", Var (params.username, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_collaborator = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      username : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Permission = struct
        let t_of_yojson = function
          | `String "pull" -> Ok "pull"
          | `String "push" -> Ok "push"
          | `String "admin" -> Ok "admin"
          | `String "maintain" -> Ok "maintain"
          | `String "triage" -> Ok "triage"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        permission : Permission.t; [@default "push"]
        permissions : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Repository_invitation.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module No_content = struct end

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
        ("204", fun _ -> Ok `No_content);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/collaborators/{username}"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("username", Var (params.username, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Check_collaborator = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      username : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_found = struct end

    let t = [ ("204", fun _ -> Ok `No_content); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/repos/{owner}/{repo}/collaborators/{username}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("username", Var (params.username, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_collaborator_permission_level = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      username : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Repository_collaborator_permission.t
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

  let url = "/repos/{owner}/{repo}/collaborators/{username}/permission"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("username", Var (params.username, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_commit_comments_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Commit_comment.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/comments"

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
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_commit_comment = struct
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
      type t = Githubc2_components.Commit_comment.t
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

  let url = "/repos/{owner}/{repo}/comments/{comment_id}"

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

module Delete_commit_comment = struct
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

  let url = "/repos/{owner}/{repo}/comments/{comment_id}"

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

module Get_commit_comment = struct
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
      type t = Githubc2_components.Commit_comment.t
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

  let url = "/repos/{owner}/{repo}/comments/{comment_id}"

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

module List_commits = struct
  module Parameters = struct
    type t = {
      author : string option; [@default None]
      owner : string;
      page : int; [@default 1]
      path : string option; [@default None]
      per_page : int; [@default 30]
      repo : string;
      sha : string option; [@default None]
      since : string option; [@default None]
      until : string option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Commit.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Conflict = struct
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
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("409", Openapi.of_json_body (fun v -> `Conflict v) Conflict.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/commits"

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
          ("sha", Var (params.sha, Option String));
          ("path", Var (params.path, Option String));
          ("author", Var (params.author, Option String));
          ("since", Var (params.since, Option String));
          ("until", Var (params.until, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_branches_for_head_commit = struct
  module Parameters = struct
    type t = {
      commit_sha : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Branch_short.t list
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

  let url = "/repos/{owner}/{repo}/commits/{commit_sha}/branches-where-head"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("commit_sha", Var (params.commit_sha, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_commit_comment = struct
  module Parameters = struct
    type t = {
      commit_sha : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        body : string;
        line : int option; [@default None]
        path : string option; [@default None]
        position : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Commit_comment.t
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

  let url = "/repos/{owner}/{repo}/commits/{commit_sha}/comments"

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
          ("commit_sha", Var (params.commit_sha, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_comments_for_commit = struct
  module Parameters = struct
    type t = {
      commit_sha : string;
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Commit_comment.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/commits/{commit_sha}/comments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("commit_sha", Var (params.commit_sha, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_pull_requests_associated_with_commit = struct
  module Parameters = struct
    type t = {
      commit_sha : string;
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pull_request_simple.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/commits/{commit_sha}/pulls"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("commit_sha", Var (params.commit_sha, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_commit = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      ref_ : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Commit.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
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
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/commits/{ref}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("ref", Var (params.ref_, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_combined_status_for_ref = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      ref_ : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Combined_commit_status.t
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

  let url = "/repos/{owner}/{repo}/commits/{ref}/status"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("ref", Var (params.ref_, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_commit_statuses_for_ref = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      ref_ : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Status.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Moved_permanently = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("301", Openapi.of_json_body (fun v -> `Moved_permanently v) Moved_permanently.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/commits/{ref}/statuses"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("ref", Var (params.ref_, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_community_profile_metrics = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Community_profile.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/community/profile"

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

module Compare_commits_with_basehead = struct
  module Parameters = struct
    type t = {
      basehead : string;
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Commit_comparison.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/compare/{basehead}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("basehead", Var (params.basehead, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Compare_commits = struct
  module Parameters = struct
    type t = {
      base : string;
      head : string;
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Commit_comparison.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

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
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "500",
          Openapi.of_json_body (fun v -> `Internal_server_error v) Internal_server_error.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/compare/{base}...{head}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("base", Var (params.base, String));
          ("head", Var (params.head, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_file = struct
  module Parameters = struct
    type t = {
      owner : string;
      path : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Author = struct
        module Primary = struct
          type t = {
            email : string option; [@default None]
            name : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Committer = struct
        module Primary = struct
          type t = {
            email : string option; [@default None]
            name : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        author : Author.t option; [@default None]
        branch : string option; [@default None]
        committer : Committer.t option; [@default None]
        message : string;
        sha : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.File_commit.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Conflict = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Service_unavailable = struct
      module Primary = struct
        type t = {
          code : string option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("409", Openapi.of_json_body (fun v -> `Conflict v) Conflict.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
        ("503", Openapi.of_json_body (fun v -> `Service_unavailable v) Service_unavailable.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/contents/{path}"

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
          ("path", Var (params.path, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_or_update_file_contents = struct
  module Parameters = struct
    type t = {
      owner : string;
      path : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Author = struct
        module Primary = struct
          type t = {
            date : string option; [@default None]
            email : string;
            name : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Committer = struct
        module Primary = struct
          type t = {
            date : string option; [@default None]
            email : string;
            name : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        author : Author.t option; [@default None]
        branch : string option; [@default None]
        committer : Committer.t option; [@default None]
        content : string;
        message : string;
        sha : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.File_commit.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Created = struct
      type t = Githubc2_components.File_commit.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Conflict = struct
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
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("409", Openapi.of_json_body (fun v -> `Conflict v) Conflict.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/contents/{path}"

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
          ("path", Var (params.path, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_content = struct
  module Parameters = struct
    type t = {
      owner : string;
      path : string;
      ref_ : string option; [@default None]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t =
        | Content_directory of Githubc2_components.Content_directory.t
        | Content_file of Githubc2_components.Content_file.t
        | Content_symlink of Githubc2_components.Content_symlink.t
        | Content_submodule of Githubc2_components.Content_submodule.t
      [@@deriving show]

      let of_yojson =
        Json_schema.one_of
          (let open CCResult in
          [
            (fun v ->
              map (fun v -> Content_directory v) (Githubc2_components.Content_directory.of_yojson v));
            (fun v -> map (fun v -> Content_file v) (Githubc2_components.Content_file.of_yojson v));
            (fun v ->
              map (fun v -> Content_symlink v) (Githubc2_components.Content_symlink.of_yojson v));
            (fun v ->
              map (fun v -> Content_submodule v) (Githubc2_components.Content_submodule.of_yojson v));
          ])

      let to_yojson = function
        | Content_directory v -> Githubc2_components.Content_directory.to_yojson v
        | Content_file v -> Githubc2_components.Content_file.to_yojson v
        | Content_symlink v -> Githubc2_components.Content_symlink.to_yojson v
        | Content_submodule v -> Githubc2_components.Content_submodule.to_yojson v
    end

    module Found = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("302", fun _ -> Ok `Found);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/contents/{path}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("path", Var (params.path, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("ref", Var (params.ref_, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_contributors = struct
  module Parameters = struct
    type t = {
      anon : string option; [@default None]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Contributor.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module No_content = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("204", fun _ -> Ok `No_content);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/contributors"

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
          ("anon", Var (params.anon, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Create_deployment = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Payload = struct
        module V0 = struct
          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
        end

        module V1 = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t =
          | V0 of V0.t
          | V1 of V1.t
        [@@deriving show]

        let of_yojson =
          Json_schema.one_of
            (let open CCResult in
            [
              (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
              (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
            ])

        let to_yojson = function
          | V0 v -> V0.to_yojson v
          | V1 v -> V1.to_yojson v
      end

      module Required_contexts = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        auto_merge : bool; [@default true]
        description : string option; [@default Some ""]
        environment : string; [@default "production"]
        payload : Payload.t option; [@default None]
        production_environment : bool option; [@default None]
        ref_ : string;
        required_contexts : Required_contexts.t option; [@default None]
        task : string; [@default "deploy"]
        transient_environment : bool; [@default false]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Deployment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Accepted = struct
      module Primary = struct
        type t = { message : string option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Conflict = struct end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("409", fun _ -> Ok `Conflict);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/deployments"

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

module List_deployments = struct
  module Parameters = struct
    type t = {
      environment : string option; [@default Some "none"]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      ref_ : string; [@default "none"]
      repo : string;
      sha : string; [@default "none"]
      task : string; [@default "none"]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Deployment.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/deployments"

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
          ("sha", Var (params.sha, String));
          ("ref", Var (params.ref_, String));
          ("task", Var (params.task, String));
          ("environment", Var (params.environment, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_deployment = struct
  module Parameters = struct
    type t = {
      deployment_id : int;
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

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/deployments/{deployment_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("deployment_id", Var (params.deployment_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_deployment = struct
  module Parameters = struct
    type t = {
      deployment_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Deployment.t
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

  let url = "/repos/{owner}/{repo}/deployments/{deployment_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("deployment_id", Var (params.deployment_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_deployment_status = struct
  module Parameters = struct
    type t = {
      deployment_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Environment = struct
        let t_of_yojson = function
          | `String "production" -> Ok "production"
          | `String "staging" -> Ok "staging"
          | `String "qa" -> Ok "qa"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module State = struct
        let t_of_yojson = function
          | `String "error" -> Ok "error"
          | `String "failure" -> Ok "failure"
          | `String "inactive" -> Ok "inactive"
          | `String "in_progress" -> Ok "in_progress"
          | `String "queued" -> Ok "queued"
          | `String "pending" -> Ok "pending"
          | `String "success" -> Ok "success"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        auto_inactive : bool option; [@default None]
        description : string; [@default ""]
        environment : Environment.t option; [@default None]
        environment_url : string; [@default ""]
        log_url : string; [@default ""]
        state : State.t;
        target_url : string; [@default ""]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Deployment_status.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/deployments/{deployment_id}/statuses"

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
          ("deployment_id", Var (params.deployment_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_deployment_statuses = struct
  module Parameters = struct
    type t = {
      deployment_id : int;
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Deployment_status.t list
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

  let url = "/repos/{owner}/{repo}/deployments/{deployment_id}/statuses"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("deployment_id", Var (params.deployment_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_deployment_status = struct
  module Parameters = struct
    type t = {
      deployment_id : int;
      owner : string;
      repo : string;
      status_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Deployment_status.t
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

  let url = "/repos/{owner}/{repo}/deployments/{deployment_id}/statuses/{status_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("deployment_id", Var (params.deployment_id, Int));
          ("status_id", Var (params.status_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_dispatch_event = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Client_payload = struct
        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
      end

      type t = {
        client_payload : Client_payload.t option; [@default None]
        event_type : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/dispatches"

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

module Get_all_environments = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Environments = struct
          type t = Githubc2_components.Environment.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          environments : Environments.t option; [@default None]
          total_count : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/environments"

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

module Delete_an_environment = struct
  module Parameters = struct
    type t = {
      environment_name : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/environments/{environment_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("environment_name", Var (params.environment_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_or_update_environment = struct
  module Parameters = struct
    type t = {
      environment_name : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Reviewers = struct
      module Items = struct
        module Primary = struct
          type t = {
            id : int option; [@default None]
            type_ : Githubc2_components.Deployment_reviewer_type.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      deployment_branch_policy : Githubc2_components.Deployment_branch_policy.t option;
          [@default None]
      reviewers : Reviewers.t option; [@default None]
      wait_timer : int option; [@default None]
    }
    [@@deriving yojson { strict = true; meta = true }, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Environment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/environments/{environment_name}"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("environment_name", Var (params.environment_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_environment = struct
  module Parameters = struct
    type t = {
      environment_name : string;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Environment.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/environments/{environment_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("environment_name", Var (params.environment_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_fork = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { organization : string option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Accepted = struct
      type t = Githubc2_components.Full_repository.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
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
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/forks"

  let make ?body params =
    Openapi.Request.make
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

module List_forks = struct
  module Parameters = struct
    module Sort = struct
      let t_of_yojson = function
        | `String "newest" -> Ok "newest"
        | `String "oldest" -> Ok "oldest"
        | `String "stargazers" -> Ok "stargazers"
        | `String "watchers" -> Ok "watchers"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
      sort : Sort.t; [@default "newest"]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Minimal_repository.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/forks"

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
          ("sort", Var (params.sort, String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Create_webhook = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Config = struct
      module Primary = struct
        type t = {
          content_type : string option; [@default None]
          digest : string option; [@default None]
          insecure_ssl : Githubc2_components.Webhook_config_insecure_ssl.t option; [@default None]
          secret : string option; [@default None]
          token : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Events = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      active : bool; [@default true]
      config : Config.t option; [@default None]
      events : Events.t;
      name : string option; [@default None]
    }
    [@@deriving yojson { strict = true; meta = true }, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Hook.t [@@deriving yojson { strict = false; meta = false }, show]
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
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/hooks"

  let make ?body params =
    Openapi.Request.make
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

module List_webhooks = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Hook.t list
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

  let url = "/repos/{owner}/{repo}/hooks"

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
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_webhook = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Add_events = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Config = struct
        module Primary = struct
          type t = {
            address : string option; [@default None]
            content_type : string option; [@default None]
            insecure_ssl : Githubc2_components.Webhook_config_insecure_ssl.t option; [@default None]
            room : string option; [@default None]
            secret : string option; [@default None]
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Events = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Remove_events = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        active : bool; [@default true]
        add_events : Add_events.t option; [@default None]
        config : Config.t option; [@default None]
        events : Events.t;
        remove_events : Remove_events.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Hook.t [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
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
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/hooks/{hook_id}"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("hook_id", Var (params.hook_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_webhook = struct
  module Parameters = struct
    type t = {
      hook_id : int;
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

  let url = "/repos/{owner}/{repo}/hooks/{hook_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("hook_id", Var (params.hook_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_webhook = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Hook.t [@@deriving yojson { strict = false; meta = false }, show]
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

  let url = "/repos/{owner}/{repo}/hooks/{hook_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("hook_id", Var (params.hook_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Update_webhook_config_for_repo = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    type t = {
      content_type : string option; [@default None]
      insecure_ssl : Githubc2_components.Webhook_config_insecure_ssl.t option; [@default None]
      secret : string option; [@default None]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = true; meta = true }, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Webhook_config.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/hooks/{hook_id}/config"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("hook_id", Var (params.hook_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Get_webhook_config_for_repo = struct
  module Parameters = struct
    type t = {
      hook_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Webhook_config.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/hooks/{hook_id}/config"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("hook_id", Var (params.hook_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_webhook_deliveries = struct
  module Parameters = struct
    type t = {
      cursor : string option; [@default None]
      hook_id : int;
      owner : string;
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Hook_delivery_item.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Bad_request = struct
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
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/hooks/{hook_id}/deliveries"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("hook_id", Var (params.hook_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("cursor", Var (params.cursor, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_webhook_delivery = struct
  module Parameters = struct
    type t = {
      delivery_id : int;
      hook_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Hook_delivery.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Bad_request = struct
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
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/hooks/{hook_id}/deliveries/{delivery_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("hook_id", Var (params.hook_id, Int));
          ("delivery_id", Var (params.delivery_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Redeliver_webhook_delivery = struct
  module Parameters = struct
    type t = {
      delivery_id : int;
      hook_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Accepted = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    module Bad_request = struct
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
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/hooks/{hook_id}/deliveries/{delivery_id}/attempts"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("hook_id", Var (params.hook_id, Int));
          ("delivery_id", Var (params.delivery_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Ping_webhook = struct
  module Parameters = struct
    type t = {
      hook_id : int;
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

  let url = "/repos/{owner}/{repo}/hooks/{hook_id}/pings"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("hook_id", Var (params.hook_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Test_push_webhook = struct
  module Parameters = struct
    type t = {
      hook_id : int;
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

  let url = "/repos/{owner}/{repo}/hooks/{hook_id}/tests"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("hook_id", Var (params.hook_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_invitations = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Repository_invitation.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/invitations"

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
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_invitation = struct
  module Parameters = struct
    type t = {
      invitation_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Permissions = struct
        let t_of_yojson = function
          | `String "read" -> Ok "read"
          | `String "write" -> Ok "write"
          | `String "maintain" -> Ok "maintain"
          | `String "triage" -> Ok "triage"
          | `String "admin" -> Ok "admin"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { permissions : Permissions.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Repository_invitation.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/invitations/{invitation_id}"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("invitation_id", Var (params.invitation_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_invitation = struct
  module Parameters = struct
    type t = {
      invitation_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/invitations/{invitation_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("invitation_id", Var (params.invitation_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_deploy_key = struct
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
        key : string;
        read_only : bool option; [@default None]
        title : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Deploy_key.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/keys"

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

module List_deploy_keys = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Deploy_key.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/keys"

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
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_deploy_key = struct
  module Parameters = struct
    type t = {
      key_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/keys/{key_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("key_id", Var (params.key_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_deploy_key = struct
  module Parameters = struct
    type t = {
      key_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Deploy_key.t
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

  let url = "/repos/{owner}/{repo}/keys/{key_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("key_id", Var (params.key_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_languages = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Language.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/languages"

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

module Disable_lfs_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/lfs"

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
      `Delete
end

module Enable_lfs_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Accepted = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    module Forbidden = struct end

    let t =
      [
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("403", fun _ -> Ok `Forbidden);
      ]
  end

  let url = "/repos/{owner}/{repo}/lfs"

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
      `Put
end

module Merge_upstream = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = { branch : string } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Merged_upstream.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Conflict = struct end
    module Unprocessable_entity = struct end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("409", fun _ -> Ok `Conflict);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/repos/{owner}/{repo}/merge-upstream"

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

module Merge = struct
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
        commit_message : string option; [@default None]
        head : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Commit.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module No_content = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct end
    module Conflict = struct end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("204", fun _ -> Ok `No_content);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", fun _ -> Ok `Not_found);
        ("409", fun _ -> Ok `Conflict);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/merges"

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

module Delete_pages_site = struct
  module Parameters = struct
    type t = {
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

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pages"

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
      `Delete
end

module Create_pages_site = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Source = struct
        module Primary = struct
          module Path = struct
            let t_of_yojson = function
              | `String "/" -> Ok "/"
              | `String "/docs" -> Ok "/docs"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = {
            branch : string;
            path : Path.t; [@default "/"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = { source : Source.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Page.t [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Conflict = struct
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
        ("409", Openapi.of_json_body (fun v -> `Conflict v) Conflict.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pages"

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

module Update_information_about_pages_site = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module V0 = struct
      module Primary = struct
        module Source = struct
          module V0 = struct
            let t_of_yojson = function
              | `String "gh-pages" -> Ok "gh-pages"
              | `String "master" -> Ok "master"
              | `String "master /docs" -> Ok "master /docs"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          module V1 = struct
            module Primary = struct
              module Path = struct
                let t_of_yojson = function
                  | `String "/" -> Ok "/"
                  | `String "/docs" -> Ok "/docs"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              type t = {
                branch : string;
                path : Path.t;
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

        type t = {
          cname : string option; [@default None]
          https_enforced : bool option; [@default None]
          public : bool option; [@default None]
          source : Source.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module V1 = struct
      module Primary = struct
        module Source = struct
          module V0 = struct
            let t_of_yojson = function
              | `String "gh-pages" -> Ok "gh-pages"
              | `String "master" -> Ok "master"
              | `String "master /docs" -> Ok "master /docs"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          module V1 = struct
            module Primary = struct
              module Path = struct
                let t_of_yojson = function
                  | `String "/" -> Ok "/"
                  | `String "/docs" -> Ok "/docs"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              type t = {
                branch : string;
                path : Path.t;
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

        type t = {
          cname : string option;
          https_enforced : bool option; [@default None]
          public : bool option; [@default None]
          source : Source.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module V2 = struct
      module Primary = struct
        module Source = struct
          module V0 = struct
            let t_of_yojson = function
              | `String "gh-pages" -> Ok "gh-pages"
              | `String "master" -> Ok "master"
              | `String "master /docs" -> Ok "master /docs"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          module V1 = struct
            module Primary = struct
              module Path = struct
                let t_of_yojson = function
                  | `String "/" -> Ok "/"
                  | `String "/docs" -> Ok "/docs"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              type t = {
                branch : string;
                path : Path.t;
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

        type t = {
          cname : string option; [@default None]
          https_enforced : bool option; [@default None]
          public : bool;
          source : Source.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module V3 = struct
      module Primary = struct
        module Source = struct
          module V0 = struct
            let t_of_yojson = function
              | `String "gh-pages" -> Ok "gh-pages"
              | `String "master" -> Ok "master"
              | `String "master /docs" -> Ok "master /docs"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          module V1 = struct
            module Primary = struct
              module Path = struct
                let t_of_yojson = function
                  | `String "/" -> Ok "/"
                  | `String "/docs" -> Ok "/docs"
                  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

                type t = (string[@of_yojson t_of_yojson])
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              type t = {
                branch : string;
                path : Path.t;
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

        type t = {
          cname : string option; [@default None]
          https_enforced : bool;
          public : bool option; [@default None]
          source : Source.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t =
      | V0 of V0.t
      | V1 of V1.t
      | V2 of V2.t
      | V3 of V3.t
    [@@deriving show]

    let of_yojson =
      Json_schema.any_of
        (let open CCResult in
        [
          (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
          (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
          (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
          (fun v -> map (fun v -> V3 v) (V3.of_yojson v));
        ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
      | V1 v -> V1.to_yojson v
      | V2 v -> V2.to_yojson v
      | V3 v -> V3.to_yojson v
  end

  module Responses = struct
    module No_content = struct end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/pages"

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
      `Put
end

module Get_pages = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Page.t [@@deriving yojson { strict = false; meta = false }, show]
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

  let url = "/repos/{owner}/{repo}/pages"

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

module Request_pages_build = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Page_build_status.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/pages/builds"

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
      `Post
end

module List_pages_builds = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Page_build.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/pages/builds"

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
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_latest_pages_build = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Page_build.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/pages/builds/latest"

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

module Get_pages_build = struct
  module Parameters = struct
    type t = {
      build_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Page_build.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/pages/builds/{build_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("build_id", Var (params.build_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_pages_health_check = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pages_health_check.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Accepted = struct
      type t = Githubc2_components.Empty_object.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Bad_request = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("400", fun _ -> Ok `Bad_request);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/repos/{owner}/{repo}/pages/health"

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

module Get_readme = struct
  module Parameters = struct
    type t = {
      owner : string;
      ref_ : string option; [@default None]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Content_file.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
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
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/readme"

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
        [ ("ref", Var (params.ref_, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_readme_in_directory = struct
  module Parameters = struct
    type t = {
      dir : string;
      owner : string;
      ref_ : string option; [@default None]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Content_file.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
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
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/readme/{dir}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("dir", Var (params.dir, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("ref", Var (params.ref_, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Create_release = struct
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
        body : string option; [@default None]
        discussion_category_name : string option; [@default None]
        draft : bool; [@default false]
        generate_release_notes : bool; [@default false]
        name : string option; [@default None]
        prerelease : bool; [@default false]
        tag_name : string;
        target_commitish : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Release.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
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
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/releases"

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

module List_releases = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Release.t list
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

  let url = "/repos/{owner}/{repo}/releases"

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
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_release_asset = struct
  module Parameters = struct
    type t = {
      asset_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        label : string option; [@default None]
        name : string option; [@default None]
        state : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Release_asset.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/releases/assets/{asset_id}"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("asset_id", Var (params.asset_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_release_asset = struct
  module Parameters = struct
    type t = {
      asset_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/releases/assets/{asset_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("asset_id", Var (params.asset_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_release_asset = struct
  module Parameters = struct
    type t = {
      asset_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Release_asset.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Found = struct end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
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

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("302", fun _ -> Ok `Found);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/releases/assets/{asset_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("asset_id", Var (params.asset_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Generate_release_notes = struct
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
        configuration_file_path : string option; [@default None]
        previous_tag_name : string option; [@default None]
        tag_name : string;
        target_commitish : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Release_notes_content.t
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

  let url = "/repos/{owner}/{repo}/releases/generate-notes"

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

module Get_latest_release = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Release.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/releases/latest"

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

module Get_release_by_tag = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      tag : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Release.t
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

  let url = "/repos/{owner}/{repo}/releases/tags/{tag}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("tag", Var (params.tag, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Update_release = struct
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
      type t = {
        body : string option; [@default None]
        discussion_category_name : string option; [@default None]
        draft : bool option; [@default None]
        name : string option; [@default None]
        prerelease : bool option; [@default None]
        tag_name : string option; [@default None]
        target_commitish : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Release.t
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

  let url = "/repos/{owner}/{repo}/releases/{release_id}"

  let make ?body params =
    Openapi.Request.make
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
      `Patch
end

module Delete_release = struct
  module Parameters = struct
    type t = {
      owner : string;
      release_id : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/releases/{release_id}"

  let make params =
    Openapi.Request.make
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
      `Delete
end

module Get_release = struct
  module Parameters = struct
    type t = {
      owner : string;
      release_id : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Release.t
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

  let url = "/repos/{owner}/{repo}/releases/{release_id}"

  let make params =
    Openapi.Request.make
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
      `Get
end

module Upload_release_asset = struct
  module Parameters = struct
    type t = {
      label : string option; [@default None]
      name : string;
      owner : string;
      release_id : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Release_asset.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unprocessable_entity = struct end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("422", fun _ -> Ok `Unprocessable_entity);
      ]
  end

  let url = "/repos/{owner}/{repo}/releases/{release_id}/assets"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("release_id", Var (params.release_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("name", Var (params.name, String)); ("label", Var (params.label, Option String)) ])
      ~url
      ~responses:Responses.t
      `Post
end

module List_release_assets = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      release_id : int;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Release_asset.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/releases/{release_id}/assets"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("release_id", Var (params.release_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_code_frequency_stats = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Code_frequency_stat.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Accepted = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    module No_content = struct end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("204", fun _ -> Ok `No_content);
      ]
  end

  let url = "/repos/{owner}/{repo}/stats/code_frequency"

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

module Get_commit_activity_stats = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Commit_activity.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Accepted = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    module No_content = struct end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("204", fun _ -> Ok `No_content);
      ]
  end

  let url = "/repos/{owner}/{repo}/stats/commit_activity"

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

module Get_contributors_stats = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Contributor_activity.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Accepted = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    module No_content = struct end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson);
        ("204", fun _ -> Ok `No_content);
      ]
  end

  let url = "/repos/{owner}/{repo}/stats/contributors"

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

module Get_participation_stats = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Participation_stats.t
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

  let url = "/repos/{owner}/{repo}/stats/participation"

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

module Get_punch_card_stats = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Code_frequency_stat.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module No_content = struct end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson); ("204", fun _ -> Ok `No_content);
      ]
  end

  let url = "/repos/{owner}/{repo}/stats/punch_card"

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

module Create_commit_status = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      sha : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module State = struct
        let t_of_yojson = function
          | `String "error" -> Ok "error"
          | `String "failure" -> Ok "failure"
          | `String "pending" -> Ok "pending"
          | `String "success" -> Ok "success"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        context : string; [@default "default"]
        description : string option; [@default None]
        state : State.t;
        target_url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Status.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/statuses/{sha}"

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
          ("sha", Var (params.sha, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_tags = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Tag.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/tags"

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
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Download_tarball_archive = struct
  module Parameters = struct
    type t = {
      owner : string;
      ref_ : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Found = struct end

    let t = [ ("302", fun _ -> Ok `Found) ]
  end

  let url = "/repos/{owner}/{repo}/tarball/{ref}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("ref", Var (params.ref_, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_teams = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Team.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/teams"

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
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Replace_all_topics = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Names = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { names : Names.t } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Topic.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
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
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/topics"

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
      `Put
end

module Get_all_topics = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Topic.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
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

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "415",
          Openapi.of_json_body (fun v -> `Unsupported_media_type v) Unsupported_media_type.of_yojson
        );
      ]
  end

  let url = "/repos/{owner}/{repo}/topics"

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
        [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_clones = struct
  module Parameters = struct
    module Per = struct
      let t_of_yojson = function
        | `String "" -> Ok ""
        | `String "day" -> Ok "day"
        | `String "week" -> Ok "week"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      owner : string;
      per : Per.t; [@default "day"]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Clone_traffic.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/traffic/clones"

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
        [ ("per", Var (params.per, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_top_paths = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Content_traffic.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/traffic/popular/paths"

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

module Get_top_referrers = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Referrer_traffic.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/traffic/popular/referrers"

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

module Get_views = struct
  module Parameters = struct
    module Per = struct
      let t_of_yojson = function
        | `String "" -> Ok ""
        | `String "day" -> Ok "day"
        | `String "week" -> Ok "week"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      owner : string;
      per : Per.t; [@default "day"]
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.View_traffic.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/traffic/views"

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
        [ ("per", Var (params.per, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Transfer = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Team_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        new_owner : string;
        team_ids : Team_ids.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Accepted = struct
      type t = Githubc2_components.Minimal_repository.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/transfer"

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

module Disable_vulnerability_alerts = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/vulnerability-alerts"

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
      `Delete
end

module Enable_vulnerability_alerts = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/vulnerability-alerts"

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
      `Put
end

module Check_vulnerability_alerts = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_found = struct end

    let t = [ ("204", fun _ -> Ok `No_content); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/repos/{owner}/{repo}/vulnerability-alerts"

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

module Download_zipball_archive = struct
  module Parameters = struct
    type t = {
      owner : string;
      ref_ : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Found = struct end

    let t = [ ("302", fun _ -> Ok `Found) ]
  end

  let url = "/repos/{owner}/{repo}/zipball/{ref}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("ref", Var (params.ref_, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_using_template = struct
  module Parameters = struct
    type t = {
      template_owner : string;
      template_repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        description : string option; [@default None]
        include_all_branches : bool; [@default false]
        name : string;
        owner : string option; [@default None]
        private_ : bool; [@default false]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Repository.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/repos/{template_owner}/{template_repo}/generate"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("template_owner", Var (params.template_owner, String));
          ("template_repo", Var (params.template_repo, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_public = struct
  module Parameters = struct
    type t = { since : int option [@default None] } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Minimal_repository.t list
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

  let url = "/repositories"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("since", Var (params.since, Option Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Create_for_authenticated_user = struct
  module Parameters = struct end

  module Request_body = struct
    module Primary = struct
      type t = {
        allow_auto_merge : bool; [@default false]
        allow_merge_commit : bool; [@default true]
        allow_rebase_merge : bool; [@default true]
        allow_squash_merge : bool; [@default true]
        auto_init : bool; [@default false]
        delete_branch_on_merge : bool; [@default false]
        description : string option; [@default None]
        gitignore_template : string option; [@default None]
        has_downloads : bool; [@default true]
        has_issues : bool; [@default true]
        has_projects : bool; [@default true]
        has_wiki : bool; [@default true]
        homepage : string option; [@default None]
        is_template : bool; [@default false]
        license_template : string option; [@default None]
        name : string;
        private_ : bool; [@default false]
        team_id : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Repository.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
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
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/user/repos"

  let make ~body () =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_for_authenticated_user = struct
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
        | `String "pushed" -> Ok "pushed"
        | `String "full_name" -> Ok "full_name"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Type = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "owner" -> Ok "owner"
        | `String "public" -> Ok "public"
        | `String "private" -> Ok "private"
        | `String "member" -> Ok "member"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Visibility = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "public" -> Ok "public"
        | `String "private" -> Ok "private"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      affiliation : string; [@default "owner,collaborator,organization_member"]
      before : string option; [@default None]
      direction : Direction.t option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 30]
      since : string option; [@default None]
      sort : Sort.t; [@default "full_name"]
      type_ : Type.t; [@default "all"]
      visibility : Visibility.t; [@default "all"]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Repository.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
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
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/user/repos"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("visibility", Var (params.visibility, String));
          ("affiliation", Var (params.affiliation, String));
          ("type", Var (params.type_, String));
          ("sort", Var (params.sort, String));
          ("direction", Var (params.direction, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
          ("since", Var (params.since, Option String));
          ("before", Var (params.before, Option String));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_invitations_for_authenticated_user = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Repository_invitation.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_modified = struct end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
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

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/repository_invitations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Accept_invitation_for_authenticated_user = struct
  module Parameters = struct
    type t = { invitation_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Conflict = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("409", Openapi.of_json_body (fun v -> `Conflict v) Conflict.of_yojson);
      ]
  end

  let url = "/user/repository_invitations/{invitation_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("invitation_id", Var (params.invitation_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Decline_invitation_for_authenticated_user = struct
  module Parameters = struct
    type t = { invitation_id : int } [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module Conflict = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("409", Openapi.of_json_body (fun v -> `Conflict v) Conflict.of_yojson);
      ]
  end

  let url = "/user/repository_invitations/{invitation_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("invitation_id", Var (params.invitation_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module List_for_user = struct
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
        | `String "pushed" -> Ok "pushed"
        | `String "full_name" -> Ok "full_name"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Type = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "owner" -> Ok "owner"
        | `String "member" -> Ok "member"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      direction : Direction.t option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 30]
      sort : Sort.t; [@default "full_name"]
      type_ : Type.t; [@default "owner"]
      username : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Minimal_repository.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/users/{username}/repos"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("username", Var (params.username, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("type", Var (params.type_, String));
          ("sort", Var (params.sort, String));
          ("direction", Var (params.direction, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end
