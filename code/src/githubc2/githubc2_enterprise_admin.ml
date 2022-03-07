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
      [@@deriving yojson { strict = false; meta = true }, show]
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
      [@@deriving yojson { strict = false; meta = true }, show]
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

      module Visibility = struct
        let t_of_yojson = function
          | `String "selected" -> Ok "selected"
          | `String "all" -> Ok "all"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        name : string;
        runners : Runners.t option; [@default None]
        selected_organization_ids : Selected_organization_ids.t option; [@default None]
        visibility : Visibility.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
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
        [ ("per_page", Var (params.per_page, Int)); ("page", Var (params.page, Int)) ])
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
      module Visibility = struct
        let t_of_yojson = function
          | `String "selected" -> Ok "selected"
          | `String "all" -> Ok "all"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        name : string option; [@default None]
        visibility : Visibility.t; [@default "all"]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
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
      [@@deriving yojson { strict = false; meta = true }, show]
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

      type t = { runners : Runners.t } [@@deriving yojson { strict = false; meta = true }, show]
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

module Get_audit_log = struct
  module Parameters = struct
    module Include = struct
      let t_of_yojson = function
        | `String "web" -> Ok "web"
        | `String "git" -> Ok "git"
        | `String "all" -> Ok "all"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    module Order = struct
      let t_of_yojson = function
        | `String "desc" -> Ok "desc"
        | `String "asc" -> Ok "asc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show]
    end

    type t = {
      after : string option; [@default None]
      before : string option; [@default None]
      enterprise : string;
      include_ : Include.t option; [@default None] [@key "include"]
      order : Order.t option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 30]
      phrase : string option; [@default None]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Audit_log_event.t list
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/audit-log"

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
          ("phrase", Var (params.phrase, Option String));
          ("include", Var (params.include_, Option String));
          ("after", Var (params.after, Option String));
          ("before", Var (params.before, Option String));
          ("order", Var (params.order, Option String));
          ("page", Var (params.page, Int));
          ("per_page", Var (params.per_page, Int));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Provision_and_invite_enterprise_group = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Members = struct
        module Items = struct
          module Primary = struct
            type t = { value : string } [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Schemas = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        displayname : string; [@key "displayName"]
        members : Members.t option; [@default None]
        schemas : Schemas.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Scim_enterprise_group.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Groups"

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

module List_provisioned_groups_enterprise = struct
  module Parameters = struct
    type t = {
      count : int option; [@default None]
      enterprise : string;
      excludedattributes : string option; [@default None] [@key "excludedAttributes"]
      filter : string option; [@default None]
      startindex : int option; [@default None] [@key "startIndex"]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Scim_group_list_enterprise.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Groups"

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
          ("startIndex", Var (params.startindex, Option Int));
          ("count", Var (params.count, Option Int));
          ("filter", Var (params.filter, Option String));
          ("excludedAttributes", Var (params.excludedattributes, Option String));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_attribute_for_enterprise_group = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      scim_group_id : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Operations = struct
        module Items = struct
          module Primary = struct
            module Op = struct
              let t_of_yojson = function
                | `String "add" -> Ok "add"
                | `String "Add" -> Ok "Add"
                | `String "remove" -> Ok "remove"
                | `String "Remove" -> Ok "Remove"
                | `String "replace" -> Ok "replace"
                | `String "Replace" -> Ok "Replace"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            module Value = struct
              module V0 = struct
                type t = string [@@deriving yojson { strict = false; meta = true }, show]
              end

              module V1 = struct
                include
                  Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
              end

              module V2 = struct
                module Items = struct
                  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
                end

                type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
              end

              type t =
                | V0 of V0.t
                | V1 of V1.t
                | V2 of V2.t
              [@@deriving show]

              let of_yojson =
                Json_schema.one_of
                  (let open CCResult in
                  [
                    (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                    (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                    (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
                  ])

              let to_yojson = function
                | V0 v -> V0.to_yojson v
                | V1 v -> V1.to_yojson v
                | V2 v -> V2.to_yojson v
            end

            type t = {
              op : Op.t;
              path : string option; [@default None]
              value : Value.t option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Schemas = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        operations : Operations.t; [@key "Operations"]
        schemas : Schemas.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Scim_enterprise_group.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Groups/{scim_group_id}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("scim_group_id", Var (params.scim_group_id, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_scim_group_from_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      scim_group_id : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Groups/{scim_group_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("scim_group_id", Var (params.scim_group_id, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Set_information_for_provisioned_enterprise_group = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      scim_group_id : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Members = struct
        module Items = struct
          module Primary = struct
            type t = { value : string } [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Schemas = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        displayname : string; [@key "displayName"]
        members : Members.t option; [@default None]
        schemas : Schemas.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Scim_enterprise_group.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Groups/{scim_group_id}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("scim_group_id", Var (params.scim_group_id, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_provisioning_information_for_enterprise_group = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      excludedattributes : string option; [@default None] [@key "excludedAttributes"]
      scim_group_id : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Scim_enterprise_group.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Groups/{scim_group_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("scim_group_id", Var (params.scim_group_id, String));
        ])
      ~query_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("excludedAttributes", Var (params.excludedattributes, Option String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module Provision_and_invite_enterprise_user = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Emails = struct
        module Items = struct
          module Primary = struct
            type t = {
              primary : bool;
              type_ : string; [@key "type"]
              value : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Groups = struct
        module Items = struct
          module Primary = struct
            type t = { value : string option [@default None] }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Name = struct
        module Primary = struct
          type t = {
            familyname : string; [@key "familyName"]
            givenname : string; [@key "givenName"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Schemas = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        emails : Emails.t;
        groups : Groups.t option; [@default None]
        name : Name.t;
        schemas : Schemas.t;
        username : string; [@key "userName"]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module Created = struct
      type t = Githubc2_components.Scim_enterprise_user.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `Created of Created.t ] [@@deriving show]

    let t = [ ("201", Openapi.of_json_body (fun v -> `Created v) Created.of_yojson) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Users"

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

module List_provisioned_identities_enterprise = struct
  module Parameters = struct
    type t = {
      count : int option; [@default None]
      enterprise : string;
      filter : string option; [@default None]
      startindex : int option; [@default None] [@key "startIndex"]
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Scim_user_list_enterprise.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Users"

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
          ("startIndex", Var (params.startindex, Option Int));
          ("count", Var (params.count, Option Int));
          ("filter", Var (params.filter, Option String));
        ])
      ~url
      ~responses:Responses.t
      `Get
end

module Update_attribute_for_enterprise_user = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      scim_user_id : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Operations = struct
        module Items = struct
          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Schemas = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        operations : Operations.t; [@key "Operations"]
        schemas : Schemas.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Scim_enterprise_user.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Users/{scim_user_id}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("scim_user_id", Var (params.scim_user_id, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Patch
end

module Delete_user_from_enterprise = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      scim_user_id : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Users/{scim_user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("scim_user_id", Var (params.scim_user_id, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Set_information_for_provisioned_enterprise_user = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      scim_user_id : string;
    }
    [@@deriving make, show]
  end

  module Request_body = struct
    module Primary = struct
      module Emails = struct
        module Items = struct
          module Primary = struct
            type t = {
              primary : bool;
              type_ : string; [@key "type"]
              value : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Groups = struct
        module Items = struct
          module Primary = struct
            type t = { value : string option [@default None] }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Name = struct
        module Primary = struct
          type t = {
            familyname : string; [@key "familyName"]
            givenname : string; [@key "givenName"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Schemas = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        emails : Emails.t;
        groups : Groups.t option; [@default None]
        name : Name.t;
        schemas : Schemas.t;
        username : string; [@key "userName"]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Scim_enterprise_user.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Users/{scim_user_id}"

  let make ~body params =
    Openapi.Request.make
      ~body:(Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("scim_user_id", Var (params.scim_user_id, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module Get_provisioning_information_for_enterprise_user = struct
  module Parameters = struct
    type t = {
      enterprise : string;
      scim_user_id : string;
    }
    [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Scim_enterprise_user.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    type t = [ `OK of OK.t ] [@@deriving show]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/scim/v2/enterprises/{enterprise}/Users/{scim_user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [
          ("enterprise", Var (params.enterprise, String));
          ("scim_user_id", Var (params.scim_user_id, String));
        ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
