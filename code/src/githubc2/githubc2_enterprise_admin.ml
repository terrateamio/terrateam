module Get_server_statistics = struct
  module Parameters = struct
    type t = {
      date_end : string option; [@default None]
      date_start : string option; [@default None]
      enterprise_or_org : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Server_statistics.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprise-installation/{enterprise_or_org}/server-statistics"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise_or_org", Var (params.enterprise_or_org, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("date_start", Var (params.date_start, Option String));
          ("date_end", Var (params.date_end, Option String));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Set_github_actions_permissions_enterprise = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      type t = {
        allowed_actions : Githubc2_components.Allowed_actions.t option; [@default None]
        enabled_organizations : Githubc2_components.Enabled_organizations.t;
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

  let url = "/enterprises/{enterprise}/actions/permissions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_github_actions_permissions_enterprise = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Actions_enterprise_permissions.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/permissions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Set_selected_organizations_enabled_github_actions_enterprise = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Selected_organization_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { selected_organization_ids : Selected_organization_ids.t }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/enterprises/{enterprise}/actions/permissions/organizations"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_selected_organizations_enabled_github_actions_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Organizations = struct
          type t = Githubc2_components.Organization_simple.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          organizations : Organizations.t;
          total_count : float;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/permissions/organizations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Disable_selected_organization_github_actions_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      org_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/enterprises/{enterprise}/actions/permissions/organizations/{org_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)); ("org_id", Var (params.org_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Enable_selected_organization_github_actions_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      org_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/enterprises/{enterprise}/actions/permissions/organizations/{org_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)); ("org_id", Var (params.org_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Set_allowed_actions_enterprise = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
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

  let url = "/enterprises/{enterprise}/actions/permissions/selected-actions"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_allowed_actions_enterprise = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Selected_actions.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/permissions/selected-actions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_self_hosted_runner_group_for_enterprise = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Runners = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Selected_organization_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Selected_workflows = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Visibility = struct
        let t_of_yojson = function
          | `String "selected" -> Ok "selected"
          | `String "all" -> Ok "all"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        allows_public_repositories : bool; [@default false]
        name : string;
        restricted_to_workflows : bool; [@default false]
        runners : Runners.t option; [@default None]
        selected_organization_ids : Selected_organization_ids.t option; [@default None]
        selected_workflows : Selected_workflows.t option; [@default None]
        visibility : Visibility.t option; [@default None]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Runner_groups_enterprise.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/runner-groups"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_self_hosted_runner_groups_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      visible_to_organization : string option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Runner_groups = struct
          type t = Githubc2_components.Runner_groups_enterprise.t list
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

  let url = "/enterprises/{enterprise}/actions/runner-groups"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("per_page", Var (params.per_page, Int));
          ("page", Var (params.page, Int));
          ("visible_to_organization", Var (params.visible_to_organization, Option String));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_self_hosted_runner_group_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Selected_workflows = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Visibility = struct
        let t_of_yojson = function
          | `String "selected" -> Ok "selected"
          | `String "all" -> Ok "all"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        allows_public_repositories : bool; [@default false]
        name : string option; [@default None]
        restricted_to_workflows : bool; [@default false]
        selected_workflows : Selected_workflows.t option; [@default None]
        visibility : Visibility.t; [@default "all"]
      }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Runner_groups_enterprise.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}"

  let make ?body params =
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_self_hosted_runner_group_from_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_self_hosted_runner_group_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Runner_groups_enterprise.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Set_org_access_to_self_hosted_runner_group_in_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Selected_organization_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { selected_organization_ids : Selected_organization_ids.t }
      [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}/organizations"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_org_access_to_self_hosted_runner_group_in_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Organizations = struct
          type t = Githubc2_components.Organization_simple.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          organizations : Organizations.t;
          total_count : float;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}/organizations"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_org_access_to_self_hosted_runner_group_in_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      org_id : int;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url =
    "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}/organizations/{org_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
          ("org_id", Var (params.org_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_org_access_to_self_hosted_runner_group_in_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      org_id : int;
      runner_group_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url =
    "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}/organizations/{org_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
          ("org_id", Var (params.org_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Set_self_hosted_runners_in_group_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
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

  let url = "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}/runners"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_self_hosted_runners_in_group_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
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

  let url = "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}/runners"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_self_hosted_runner_from_group_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
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

  let url = "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
          ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_self_hosted_runner_to_group_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
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

  let url = "/enterprises/{enterprise}/actions/runner-groups/{runner_group_id}/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_group_id", Var (params.runner_group_id, Int));
          ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_self_hosted_runners_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
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
          runners : Runners.t option; [@default None]
          total_count : float option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/runners"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module List_runner_applications_for_enterprise = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Runner_application.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/runners/downloads"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Create_registration_token_for_enterprise = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Authentication_token.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/runners/registration-token"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Create_remove_token_for_enterprise = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Authentication_token.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/actions/runners/remove-token"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("enterprise", Var (params.enterprise, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Delete_self_hosted_runner_from_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/enterprises/{enterprise}/actions/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String)); ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_self_hosted_runner_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
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

  let url = "/enterprises/{enterprise}/actions/runners/{runner_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String)); ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_all_custom_labels_from_self_hosted_runner_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Labels = struct
          type t = Githubc2_components.Runner_label.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          labels : Labels.t;
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

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/enterprises/{enterprise}/actions/runners/{runner_id}/labels"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String)); ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Add_custom_labels_to_self_hosted_runner_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Labels = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { labels : Labels.t } [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Labels = struct
          type t = Githubc2_components.Runner_label.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          labels : Labels.t;
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

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/enterprises/{enterprise}/actions/runners/{runner_id}/labels"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String)); ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module Set_custom_labels_for_self_hosted_runner_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Labels = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = { labels : Labels.t } [@@deriving make, yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Labels = struct
          type t = Githubc2_components.Runner_label.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          labels : Labels.t;
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

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/enterprises/{enterprise}/actions/runners/{runner_id}/labels"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String)); ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module List_labels_for_self_hosted_runner_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Labels = struct
          type t = Githubc2_components.Runner_label.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          labels : Labels.t;
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

  let url = "/enterprises/{enterprise}/actions/runners/{runner_id}/labels"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String)); ("runner_id", Var (params.runner_id, Int));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Remove_custom_label_from_self_hosted_runner_for_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      name : string;
      runner_id : int;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Labels = struct
          type t = Githubc2_components.Runner_label.t list
          [@@deriving yojson { strict = false; meta = false }, show]
        end

        type t = {
          labels : Labels.t;
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

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error_simple.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t =
      [ `OK of OK.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/enterprises/{enterprise}/actions/runners/{runner_id}/labels/{name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("runner_id", Var (params.runner_id, Int));
          ("name", Var (params.name, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end
