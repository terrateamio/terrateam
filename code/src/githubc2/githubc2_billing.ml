module Get_github_actions_billing_ghe = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Actions_billing_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/settings/billing/actions"

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

module Get_github_packages_billing_ghe = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Packages_billing_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/settings/billing/packages"

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

module Get_shared_storage_billing_ghe = struct
  module Parameters = struct
    type t = { enterprise : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Combined_billing_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/enterprises/{enterprise}/settings/billing/shared-storage"

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

module Get_github_actions_billing_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Actions_billing_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/settings/billing/actions"

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

module Get_github_packages_billing_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Packages_billing_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/settings/billing/packages"

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

module Get_shared_storage_billing_org = struct
  module Parameters = struct
    type t = { org : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Combined_billing_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/settings/billing/shared-storage"

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

module Get_github_actions_billing_user = struct
  module Parameters = struct
    type t = { username : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Actions_billing_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/users/{username}/settings/billing/actions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("username", Var (params.username, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_github_packages_billing_user = struct
  module Parameters = struct
    type t = { username : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Packages_billing_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/users/{username}/settings/billing/packages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("username", Var (params.username, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Get_shared_storage_billing_user = struct
  module Parameters = struct
    type t = { username : string } [@@deriving make, show]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Combined_billing_usage.t
      [@@deriving yojson { strict = false; meta = false }, show]
    end

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/users/{username}/settings/billing/shared-storage"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
        let open Parameters in
        [ ("username", Var (params.username, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
