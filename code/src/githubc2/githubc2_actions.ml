module Set_github_actions_permissions_organization = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        allowed_actions : Githubc2_components.Allowed_actions.t option; [@default None]
        enabled_repositories : Githubc2_components.Enabled_repositories.t;
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/permissions"

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
      `Put
end

module Get_github_actions_permissions_organization = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Actions_organization_permissions.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/permissions"

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

module Set_selected_repositories_enabled_github_actions_organization = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
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

  let url = "/orgs/{org}/actions/permissions/repositories"

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
      `Put
end

module List_selected_repositories_enabled_github_actions_organization = struct
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
        module Repositories = struct
          type t = Githubc2_components.Repository.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          repositories : Repositories.t;
          total_count : float;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/permissions/repositories"

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

module Disable_selected_repository_github_actions_organization = struct
  module Parameters = struct
    type t = {
      org : string;
      repository_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/permissions/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)); ("repository_id", Var (params.repository_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Enable_selected_repository_github_actions_organization = struct
  module Parameters = struct
    type t = {
      org : string;
      repository_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/permissions/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)); ("repository_id", Var (params.repository_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Set_allowed_actions_organization = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Request_body = struct
    type t = Githubc2_components.Selected_actions.t
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/permissions/selected-actions"

  let make ?body params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_allowed_actions_organization = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Selected_actions.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/permissions/selected-actions"

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

module Create_self_hosted_runner_group_for_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Runners = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Selected_repository_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Visibility = struct
        let t_of_yojson = function
          | `String "selected" -> Ok "selected"
          | `String "all" -> Ok "all"
          | `String "private" -> Ok "private"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        name : string;
        runners : Runners.t option; [@default None]
        selected_repository_ids : Selected_repository_ids.t option; [@default None]
        visibility : Visibility.t; [@default "all"]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Runner_groups_org.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runner-groups"

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

module List_self_hosted_runner_groups_for_org = struct
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
        module Runner_groups = struct
          type t = Githubc2_components.Runner_groups_org.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          runner_groups : Runner_groups.t;
          total_count : float;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runner-groups"

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

module Update_self_hosted_runner_group_for_org = struct
  module Parameters = struct
    type t = {
      org : string;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Visibility = struct
        let t_of_yojson = function
          | `String "selected" -> Ok "selected"
          | `String "all" -> Ok "all"
          | `String "private" -> Ok "private"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        name : string;
        visibility : Visibility.t option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Runner_groups_org.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String)); ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_self_hosted_runner_group_from_org = struct
  module Parameters = struct
    type t = {
      org : string;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String)); ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_self_hosted_runner_group_for_org = struct
  module Parameters = struct
    type t = {
      org : string;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Runner_groups_org.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String)); ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Set_repo_access_to_self_hosted_runner_group_in_org = struct
  module Parameters = struct
    type t = {
      org : string;
      runner_group_id : int;
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

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}/repositories"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String)); ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_repo_access_to_self_hosted_runner_group_in_org = struct
  module Parameters = struct
    type t = {
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      runner_group_id : int;
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
          total_count : float;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}/repositories"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String)); ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_repo_access_to_self_hosted_runner_group_in_org = struct
  module Parameters = struct
    type t = {
      org : string;
      repository_id : int;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
          ("repository_id", Var (params.repository_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_repo_access_to_self_hosted_runner_group_in_org = struct
  module Parameters = struct
    type t = {
      org : string;
      repository_id : int;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}/repositories/{repository_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
          ("repository_id", Var (params.repository_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Set_self_hosted_runners_in_group_for_org = struct
  module Parameters = struct
    type t = {
      org : string;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Runners = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { runners : Runners.t }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}/runners"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String)); ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_self_hosted_runners_in_group_for_org = struct
  module Parameters = struct
    type t = {
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Runners = struct
          type t = Githubc2_components.Runner.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          runners : Runners.t;
          total_count : float;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}/runners"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String)); ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_self_hosted_runner_from_group_for_org = struct
  module Parameters = struct
    type t = {
      org : string;
      runner_group_id : int;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
          ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_self_hosted_runner_to_group_for_org = struct
  module Parameters = struct
    type t = {
      org : string;
      runner_group_id : int;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/runner-groups/{runner_group_id}/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("org", Var (params.org, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
          ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_self_hosted_runners_for_org = struct
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
        module Runners = struct
          type t = Githubc2_components.Runner.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          runners : Runners.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runners"

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

module List_runner_applications_for_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Runner_application.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runners/downloads"

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

module Create_registration_token_for_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Authentication_token.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runners/registration-token"

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
      `Post
end

module Create_remove_token_for_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Authentication_token.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runners/remove-token"

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
      `Post
end

module Delete_self_hosted_runner_from_org = struct
  module Parameters = struct
    type t = {
      org : string;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/orgs/{org}/actions/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)); ("runner_id", Var (params.runner_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_self_hosted_runner_for_org = struct
  module Parameters = struct
    type t = {
      org : string;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Runner.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("org", Var (params.org, String)); ("runner_id", Var (params.runner_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

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
          type t = Githubc2_components.Organization_actions_secret.t list
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

  let url = "/orgs/{org}/actions/secrets"

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
      type t = Githubc2_components.Actions_public_key.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/secrets/public-key"

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

  let url = "/orgs/{org}/actions/secrets/{secret_name}"

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
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
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

  let url = "/orgs/{org}/actions/secrets/{secret_name}"

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
      type t = Githubc2_components.Organization_actions_secret.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/actions/secrets/{secret_name}"

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

  let url = "/orgs/{org}/actions/secrets/{secret_name}/repositories"

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

  let url = "/orgs/{org}/actions/secrets/{secret_name}/repositories"

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

  let url = "/orgs/{org}/actions/secrets/{secret_name}/repositories/{repository_id}"

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

  let url = "/orgs/{org}/actions/secrets/{secret_name}/repositories/{repository_id}"

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

module List_artifacts_for_repo = struct
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
        module Artifacts = struct
          type t = Githubc2_components.Artifact.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          artifacts : Artifacts.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/artifacts"

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

module Delete_artifact = struct
  module Parameters = struct
    type t = {
      artifact_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/actions/artifacts/{artifact_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("artifact_id", Var (params.artifact_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_artifact = struct
  module Parameters = struct
    type t = {
      artifact_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Artifact.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/artifacts/{artifact_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("artifact_id", Var (params.artifact_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Download_artifact = struct
  module Parameters = struct
    type t = {
      archive_format : string;
      artifact_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Found = struct end

    type t = [ `Found ] [@@deriving show]

    let t = [ ("302", fun _ -> Ok `Found) ]
  end

  let url = "/repos/{owner}/{repo}/actions/artifacts/{artifact_id}/{archive_format}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("artifact_id", Var (params.artifact_id, Int));
          ("archive_format", Var (params.archive_format, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_job_for_workflow_run = struct
  module Parameters = struct
    type t = {
      job_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Job.t [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/jobs/{job_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("job_id", Var (params.job_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Download_job_logs_for_workflow_run = struct
  module Parameters = struct
    type t = {
      job_id : int;
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Found = struct end

    type t = [ `Found ] [@@deriving show]

    let t = [ ("302", fun _ -> Ok `Found) ]
  end

  let url = "/repos/{owner}/{repo}/actions/jobs/{job_id}/logs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("job_id", Var (params.job_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Set_github_actions_permissions_repository = struct
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
        allowed_actions : Githubc2_components.Allowed_actions.t option; [@default None]
        enabled : bool;
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/actions/permissions"

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

module Get_github_actions_permissions_repository = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Actions_repository_permissions.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/permissions"

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

module Set_allowed_actions_repository = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    type t = Githubc2_components.Selected_actions.t
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/actions/permissions/selected-actions"

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
      `Put
end

module Get_allowed_actions_repository = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Selected_actions.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/permissions/selected-actions"

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

module List_self_hosted_runners_for_repo = struct
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
        module Runners = struct
          type t = Githubc2_components.Runner.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          runners : Runners.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runners"

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

module List_runner_applications_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Runner_application.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runners/downloads"

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

module Create_registration_token_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Authentication_token.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runners/registration-token"

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

module Create_remove_token_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Authentication_token.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runners/remove-token"

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

module Delete_self_hosted_runner_from_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_self_hosted_runner_for_repo = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Runner.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_workflow_runs_for_repo = struct
  module Parameters = struct
    module Status = struct
      let t_of_yojson = function
        | `String "completed" -> Ok "completed"
        | `String "action_required" -> Ok "action_required"
        | `String "cancelled" -> Ok "cancelled"
        | `String "failure" -> Ok "failure"
        | `String "neutral" -> Ok "neutral"
        | `String "skipped" -> Ok "skipped"
        | `String "stale" -> Ok "stale"
        | `String "success" -> Ok "success"
        | `String "timed_out" -> Ok "timed_out"
        | `String "in_progress" -> Ok "in_progress"
        | `String "queued" -> Ok "queued"
        | `String "requested" -> Ok "requested"
        | `String "waiting" -> Ok "waiting"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      actor : string option; [@default None]
      branch : string option; [@default None]
      created : string option; [@default None]
      event : string option; [@default None]
      exclude_pull_requests : bool; [@default false]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
      status : Status.t option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Workflow_runs = struct
          type t = Githubc2_components.Workflow_run.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          total_count : int;
          workflow_runs : Workflow_runs.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs"

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
          ("actor", Var (params.actor, Option String));
          ("branch", Var (params.branch, Option String));
          ("event", Var (params.event, Option String));
          ("status", Var (params.status, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
          ("created", Var (params.created, Option String));
          ("exclude_pull_requests", Var (params.exclude_pull_requests, Bool));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_workflow_run = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_workflow_run = struct
  module Parameters = struct
    type t = {
      exclude_pull_requests : bool; [@default false]
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Workflow_run.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("exclude_pull_requests", Var (params.exclude_pull_requests, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_reviews_for_run = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Environment_approvals.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/approvals"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Approve_workflow_run = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Empty_object.t
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

    type t =
      [ `Created of Created.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/approve"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_workflow_run_artifacts = struct
  module Parameters = struct
    type t = {
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Artifacts = struct
          type t = Githubc2_components.Artifact.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          artifacts : Artifacts.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/artifacts"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_workflow_run_attempt = struct
  module Parameters = struct
    type t = {
      attempt_number : int;
      exclude_pull_requests : bool; [@default false]
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Workflow_run.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/attempts/{attempt_number}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
          ("attempt_number", Var (params.attempt_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("exclude_pull_requests", Var (params.exclude_pull_requests, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_jobs_for_workflow_run_attempt = struct
  module Parameters = struct
    type t = {
      attempt_number : int;
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Jobs = struct
          type t = Githubc2_components.Job.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          jobs : Jobs.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/attempts/{attempt_number}/jobs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
          ("attempt_number", Var (params.attempt_number, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Download_workflow_run_attempt_logs = struct
  module Parameters = struct
    type t = {
      attempt_number : int;
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Found = struct end

    type t = [ `Found ] [@@deriving show]

    let t = [ ("302", fun _ -> Ok `Found) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/attempts/{attempt_number}/logs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
          ("attempt_number", Var (params.attempt_number, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Cancel_workflow_run = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Accepted = struct
      type t = Json_schema.Empty_obj.t [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Accepted of Accepted.t ] [@@deriving show]

    let t = [ ("202", Openapi.of_json_body (fun v -> `Accepted v) Accepted.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/cancel"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_jobs_for_workflow_run = struct
  module Parameters = struct
    module Filter = struct
      let t_of_yojson = function
        | `String "latest" -> Ok "latest"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      filter : Filter.t; [@default "latest"]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Jobs = struct
          type t = Githubc2_components.Job.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          jobs : Jobs.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/jobs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("filter", Var (params.filter, String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_workflow_run_logs = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/logs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Download_workflow_run_logs = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Found = struct end

    type t = [ `Found ] [@@deriving show]

    let t = [ ("302", fun _ -> Ok `Found) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/logs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Review_pending_deployments_for_run = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Environment_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module State = struct
        let t_of_yojson = function
          | `String "approved" -> Ok "approved"
          | `String "rejected" -> Ok "rejected"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        comment : string;
        environment_ids : Environment_ids.t;
        state : State.t;
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Deployment.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/pending_deployments"

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
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Get_pending_deployments_for_run = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Pending_deployment.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/pending_deployments"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Re_run_workflow = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module Created = struct
      type t = Json_schema.Empty_obj.t [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/rerun"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Get_workflow_run_usage = struct
  module Parameters = struct
    type t = {
      owner : string;
      repo : string;
      run_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Workflow_run_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/runs/{run_id}/timing"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ("run_id", Var (params.run_id, Int));
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
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Secrets = struct
          type t = Githubc2_components.Actions_secret.t list
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

  let url = "/repos/{owner}/{repo}/actions/secrets"

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
      type t = Githubc2_components.Actions_public_key.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/secrets/public-key"

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

  let url = "/repos/{owner}/{repo}/actions/secrets/{secret_name}"

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
      type t = Json_schema.Empty_obj.t [@@deriving yojson { strict = false; meta = false }, show]
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

  let url = "/repos/{owner}/{repo}/actions/secrets/{secret_name}"

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
      type t = Githubc2_components.Actions_secret.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/secrets/{secret_name}"

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

module List_repo_workflows = struct
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
        module Workflows = struct
          type t = Githubc2_components.Workflow.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          total_count : int;
          workflows : Workflows.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/workflows"

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

module Get_workflow = struct
  module Parameters = struct
    module Workflow_id = struct
      module V0 = struct
        type t = int [@@deriving show]
      end

      module V1 = struct
        type t = string [@@deriving show]
      end

      type t =
        | V0 of V0.t
        | V1 of V1.t
      [@@deriving show]
    end

    type t = {
      owner : string;
      repo : string;
      workflow_id : Workflow_id.t;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Workflow.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/workflows/{workflow_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ( "workflow_id",
            match params.workflow_id with
            | Workflow_id.V0 v -> Var (v, Int)
            | Workflow_id.V1 v -> Var (v, String) );
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Disable_workflow = struct
  module Parameters = struct
    module Workflow_id = struct
      module V0 = struct
        type t = int [@@deriving show]
      end

      module V1 = struct
        type t = string [@@deriving show]
      end

      type t =
        | V0 of V0.t
        | V1 of V1.t
      [@@deriving show]
    end

    type t = {
      owner : string;
      repo : string;
      workflow_id : Workflow_id.t;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/actions/workflows/{workflow_id}/disable"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ( "workflow_id",
            match params.workflow_id with
            | Workflow_id.V0 v -> Var (v, Int)
            | Workflow_id.V1 v -> Var (v, String) );
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Create_workflow_dispatch = struct
  module Parameters = struct
    module Workflow_id = struct
      module V0 = struct
        type t = int [@@deriving show]
      end

      module V1 = struct
        type t = string [@@deriving show]
      end

      type t =
        | V0 of V0.t
        | V1 of V1.t
      [@@deriving show]
    end

    type t = {
      owner : string;
      repo : string;
      workflow_id : Workflow_id.t;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Inputs = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      type t = {
        inputs : Inputs.t option; [@default None]
        ref_ : string; [@key "ref"]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches"

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
          ( "workflow_id",
            match params.workflow_id with
            | Workflow_id.V0 v -> Var (v, Int)
            | Workflow_id.V1 v -> Var (v, String) );
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Enable_workflow = struct
  module Parameters = struct
    module Workflow_id = struct
      module V0 = struct
        type t = int [@@deriving show]
      end

      module V1 = struct
        type t = string [@@deriving show]
      end

      type t =
        | V0 of V0.t
        | V1 of V1.t
      [@@deriving show]
    end

    type t = {
      owner : string;
      repo : string;
      workflow_id : Workflow_id.t;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repos/{owner}/{repo}/actions/workflows/{workflow_id}/enable"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ( "workflow_id",
            match params.workflow_id with
            | Workflow_id.V0 v -> Var (v, Int)
            | Workflow_id.V1 v -> Var (v, String) );
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_workflow_runs = struct
  module Parameters = struct
    module Status = struct
      let t_of_yojson = function
        | `String "completed" -> Ok "completed"
        | `String "action_required" -> Ok "action_required"
        | `String "cancelled" -> Ok "cancelled"
        | `String "failure" -> Ok "failure"
        | `String "neutral" -> Ok "neutral"
        | `String "skipped" -> Ok "skipped"
        | `String "stale" -> Ok "stale"
        | `String "success" -> Ok "success"
        | `String "timed_out" -> Ok "timed_out"
        | `String "in_progress" -> Ok "in_progress"
        | `String "queued" -> Ok "queued"
        | `String "requested" -> Ok "requested"
        | `String "waiting" -> Ok "waiting"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Workflow_id = struct
      module V0 = struct
        type t = int [@@deriving show]
      end

      module V1 = struct
        type t = string [@@deriving show]
      end

      type t =
        | V0 of V0.t
        | V1 of V1.t
      [@@deriving show]
    end

    type t = {
      actor : string option; [@default None]
      branch : string option; [@default None]
      created : string option; [@default None]
      event : string option; [@default None]
      exclude_pull_requests : bool; [@default false]
      owner : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repo : string;
      status : Status.t option; [@default None]
      workflow_id : Workflow_id.t;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Workflow_runs = struct
          type t = Githubc2_components.Workflow_run.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          total_count : int;
          workflow_runs : Workflow_runs.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/workflows/{workflow_id}/runs"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ( "workflow_id",
            match params.workflow_id with
            | Workflow_id.V0 v -> Var (v, Int)
            | Workflow_id.V1 v -> Var (v, String) );
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("actor", Var (params.actor, Option String));
          ("branch", Var (params.branch, Option String));
          ("event", Var (params.event, Option String));
          ("status", Var (params.status, Option String));
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
          ("created", Var (params.created, Option String));
          ("exclude_pull_requests", Var (params.exclude_pull_requests, Bool));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_workflow_usage = struct
  module Parameters = struct
    module Workflow_id = struct
      module V0 = struct
        type t = int [@@deriving show]
      end

      module V1 = struct
        type t = string [@@deriving show]
      end

      type t =
        | V0 of V0.t
        | V1 of V1.t
      [@@deriving show]
    end

    type t = {
      owner : string;
      repo : string;
      workflow_id : Workflow_id.t;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Workflow_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repos/{owner}/{repo}/actions/workflows/{workflow_id}/timing"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("owner", Var (params.owner, String));
          ("repo", Var (params.repo, String));
          ( "workflow_id",
            match params.workflow_id with
            | Workflow_id.V0 v -> Var (v, Int)
            | Workflow_id.V1 v -> Var (v, String) );
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module List_environment_secrets = struct
  module Parameters = struct
    type t = {
      environment_name : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      repository_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Secrets = struct
          type t = Githubc2_components.Actions_secret.t list
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

  let url = "/repositories/{repository_id}/environments/{environment_name}/secrets"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("repository_id", Var (params.repository_id, Int));
          ("environment_name", Var (params.environment_name, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_environment_public_key = struct
  module Parameters = struct
    type t = {
      environment_name : string;
      repository_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Actions_public_key.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repositories/{repository_id}/environments/{environment_name}/secrets/public-key"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("repository_id", Var (params.repository_id, Int));
          ("environment_name", Var (params.environment_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_environment_secret = struct
  module Parameters = struct
    type t = {
      environment_name : string;
      repository_id : int;
      secret_name : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/repositories/{repository_id}/environments/{environment_name}/secrets/{secret_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("repository_id", Var (params.repository_id, Int));
          ("environment_name", Var (params.environment_name, String));
          ("secret_name", Var (params.secret_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Create_or_update_environment_secret = struct
  module Parameters = struct
    type t = {
      environment_name : string;
      repository_id : int;
      secret_name : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        encrypted_value : string;
        key_id : string;
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

  let url = "/repositories/{repository_id}/environments/{environment_name}/secrets/{secret_name}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("repository_id", Var (params.repository_id, Int));
          ("environment_name", Var (params.environment_name, String));
          ("secret_name", Var (params.secret_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_environment_secret = struct
  module Parameters = struct
    type t = {
      environment_name : string;
      repository_id : int;
      secret_name : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Actions_secret.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/repositories/{repository_id}/environments/{environment_name}/secrets/{secret_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("repository_id", Var (params.repository_id, Int));
          ("environment_name", Var (params.environment_name, String));
          ("secret_name", Var (params.secret_name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
