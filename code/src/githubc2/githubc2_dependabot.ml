module List_org_secrets = struct
  module Parameters = struct
    type t = {
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Secrets = struct
          type t = Githubc2_components.Organization_dependabot_secret.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          secrets : Secrets.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/dependabot/secrets"

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
         [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_org_public_key = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Dependabot_public_key.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/dependabot/secrets/public-key"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("org", Var (params.org, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_org_secret = struct
  module Parameters = struct
    type t = {
      org : string;
      secret_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/dependabot/secrets/{secret_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("org", Var (params.org, String)); ("secret_name", Var (params.secret_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_or_update_org_secret = struct
  module Parameters = struct
    type t = {
      org : string;
      secret_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    module Primary = struct
      module Selected_repository_ids = struct
        module Items = struct
          module V0 = struct
            type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module V1 = struct
            type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t =
            | V0 of V0.t
            | V1 of V1.t
          [@@deriving show, eq]

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

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Visibility = struct
        let t_of_yojson = function
          | `String "all" -> Ok "all"
          | `String "private" -> Ok "private"
          | `String "selected" -> Ok "selected"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        encrypted_value : string option; [@default None]
        key_id : string option; [@default None]
        selected_repository_ids : Selected_repository_ids.t option; [@default None]
        visibility : Visibility.t;
      }
      [@@deriving make, yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Empty_object.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module No_content = struct end

    type t =
      [ `Created of Created.t
      | `No_content
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("204", fun _ -> Ok `No_content);
      ]
  end

  let url = "/orgs/{org}/dependabot/secrets/{secret_name}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("org", Var (params.org, String)); ("secret_name", Var (params.secret_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_org_secret = struct
  module Parameters = struct
    type t = {
      org : string;
      secret_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Organization_dependabot_secret.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/dependabot/secrets/{secret_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("org", Var (params.org, String)); ("secret_name", Var (params.secret_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Set_selected_repos_for_org_secret = struct
  module Parameters = struct
    type t = {
      org : string;
      secret_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    module Primary = struct
      module Selected_repository_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { selected_repository_ids : Selected_repository_ids.t }
      [@@deriving make, yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/dependabot/secrets/{secret_name}/repositories"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("org", Var (params.org, String)); ("secret_name", Var (params.secret_name, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_selected_repos_for_org_secret = struct
  module Parameters = struct
    type t = {
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      secret_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Repositories = struct
          type t = Githubc2_components.Minimal_repository.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          repositories : Repositories.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/dependabot/secrets/{secret_name}/repositories"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("org", Var (params.org, String)); ("secret_name", Var (params.secret_name, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_selected_repo_from_org_secret = struct
  module Parameters = struct
    type t = {
      org : string;
      repository_id : int;
      secret_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Conflict = struct end

    type t =
      [ `No_content
      | `Conflict
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("409", fun _ -> Ok `Conflict) ]
  end

  let url = "/orgs/{org}/dependabot/secrets/{secret_name}/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("org", Var (params.org, String));
           ("secret_name", Var (params.secret_name, String));
           ("repository_id", Var (params.repository_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_selected_repo_to_org_secret = struct
  module Parameters = struct
    type t = {
      org : string;
      repository_id : int;
      secret_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Conflict = struct end

    type t =
      [ `No_content
      | `Conflict
      ]
    [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content); ("409", fun _ -> Ok `Conflict) ]
  end

  let url = "/orgs/{org}/dependabot/secrets/{secret_name}/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("org", Var (params.org, String));
           ("secret_name", Var (params.secret_name, String));
           ("repository_id", Var (params.repository_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_alerts_for_repo = struct
  module Parameters = struct
    module Direction = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "updated" -> Ok "updated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      direction : Direction.t; [@default "desc"]
      ecosystem : string option; [@default None]
      manifest : string option; [@default None]
      owner : string;
      package : string option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
      scope : Githubc2_components.Dependabot_alert_scope.t;
      severity : string option; [@default None]
      sort : Sort.t; [@default "created"]
      state : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Dependabot_alert.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/dependabot/alerts"

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
           ("state", Var (params.state, Option String));
           ("severity", Var (params.severity, Option String));
           ("ecosystem", Var (params.ecosystem, Option String));
           ("package", Var (params.package, Option String));
           ("manifest", Var (params.manifest, Option String));
           ("scope", Var (params.scope, Option String));
           ("sort", Var (params.sort, String));
           ("direction", Var (params.direction, String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_alert = struct
  module Parameters = struct
    type t = {
      alert_number : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = {
      dismissed_comment : string option; [@default None]
      dismissed_reason : Githubc2_components.Dependabot_alert_dismissed_reason.t option;
          [@default None]
      state : Githubc2_components.Dependabot_alert_set_state.t;
    }
    [@@deriving make, yojson { strict = true; meta = true }, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Dependabot_alert.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_modified = struct end

    module Bad_request = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Conflict = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Bad_request of Bad_request.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Conflict of Conflict.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("400", Openapi.of_json_body (fun v -> `Bad_request v) Bad_request.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ("409", Openapi.of_json_body (fun v -> `Conflict v) Conflict.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/repos/{owner}/{repo}/dependabot/alerts/{alert_number}"

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
           ("alert_number", Var (params.alert_number, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Get_alert = struct
  module Parameters = struct
    type t = {
      alert_number : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Dependabot_alert.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/dependabot/alerts/{alert_number}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("owner", Var (params.owner, String));
           ("repo", Var (params.repo, String));
           ("alert_number", Var (params.alert_number, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_repo_secrets = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Secrets = struct
          type t = Githubc2_components.Dependabot_secret.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          secrets : Secrets.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/dependabot/secrets"

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

module Get_repo_public_key = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Dependabot_public_key.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/dependabot/secrets/public-key"

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

module Delete_repo_secret = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      secret_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/dependabot/secrets/{secret_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("owner", Var (params.owner, String));
           ("repo", Var (params.repo, String));
           ("secret_name", Var (params.secret_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_or_update_repo_secret = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      secret_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        encrypted_value : string option; [@default None]
        key_id : string option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Empty_object.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module No_content = struct end

    type t =
      [ `Created of Created.t
      | `No_content
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("204", fun _ -> Ok `No_content);
      ]
  end

  let url = "/repos/{owner}/{repo}/dependabot/secrets/{secret_name}"

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
           ("secret_name", Var (params.secret_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_repo_secret = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      secret_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Dependabot_secret.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/dependabot/secrets/{secret_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("owner", Var (params.owner, String));
           ("repo", Var (params.repo, String));
           ("secret_name", Var (params.secret_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
