module List_org_secrets = struct
  module Parameters = struct
    type t = {
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Secrets = struct
          type t = Githubc2_components.Organization_dependabot_secret.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          secrets : Secrets.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

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
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Dependabot_public_key.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

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
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

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
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Selected_repository_ids = struct
        module Items = struct
          module V0 = struct
            type t = string [@@deriving yojson { strict = false; meta = true }, show]
          end

          module V1 = struct
            type t = int [@@deriving yojson { strict = false; meta = true }, show]
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

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Visibility = struct
        let t_of_yojson = function
          | `String "all" -> Ok "all"
          | `String "private" -> Ok "private"
          | `String "selected" -> Ok "selected"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        encrypted_value : string option; [@default None]
        key_id : string option; [@default None]
        selected_repository_ids : Selected_repository_ids.t option; [@default None]
        visibility : Visibility.t;
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Empty_object.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module No_content = struct end

    type t =
      [ `Created of Created.t
      | `No_content
      ]
    [@@deriving show]

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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Organization_dependabot_secret.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

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
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Selected_repository_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { selected_repository_ids : Selected_repository_ids.t }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Repositories = struct
          type t = Githubc2_components.Minimal_repository.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          repositories : Repositories.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

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
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Conflict = struct end

    type t =
      [ `No_content
      | `Conflict
      ]
    [@@deriving show]

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
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end
    module Conflict = struct end

    type t =
      [ `No_content
      | `Conflict
      ]
    [@@deriving show]

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

module List_repo_secrets = struct
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
      module Primary = struct
        module Secrets = struct
          type t = Githubc2_components.Dependabot_secret.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          secrets : Secrets.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Dependabot_public_key.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

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
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

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
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        encrypted_value : string option; [@default None]
        key_id : string option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Empty_object.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    module No_content = struct end

    type t =
      [ `Created of Created.t
      | `No_content
      ]
    [@@deriving show]

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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Dependabot_secret.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

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