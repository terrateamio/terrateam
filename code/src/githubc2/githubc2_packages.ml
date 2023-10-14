module List_packages_for_organization = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Visibility = struct
      let t_of_yojson = function
        | `String "public" -> Ok "public"
        | `String "private" -> Ok "private"
        | `String "internal" -> Ok "internal"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      org : string;
      package_type : Package_type.t;
      visibility : Visibility.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/orgs/{org}/packages"

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
           ("package_type", Var (params.package_type, String));
           ("visibility", Var (params.visibility, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_package_for_org = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      org : string;
      package_name : string;
      package_type : Package_type.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/orgs/{org}/packages/{package_type}/{package_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("org", Var (params.org, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_package_for_organization = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      org : string;
      package_name : string;
      package_type : Package_type.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/packages/{package_type}/{package_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("org", Var (params.org, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Restore_package_for_org = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      org : string;
      package_name : string;
      package_type : Package_type.t;
      token : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/orgs/{org}/packages/{package_type}/{package_name}/restore"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("org", Var (params.org, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("token", Var (params.token, Option String)) ])
      ~url
      ~responses:Responses.t
      `Post
end

module Get_all_package_versions_for_package_owned_by_org = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module State = struct
      let t_of_yojson = function
        | `String "active" -> Ok "active"
        | `String "deleted" -> Ok "deleted"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      org : string;
      package_name : string;
      package_type : Package_type.t;
      page : int; [@default 1]
      per_page : int; [@default 30]
      state : State.t; [@default "active"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package_version.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
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

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/orgs/{org}/packages/{package_type}/{package_name}/versions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("org", Var (params.org, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("state", Var (params.state, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_package_version_for_org = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      org : string;
      package_name : string;
      package_type : Package_type.t;
      package_version_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/orgs/{org}/packages/{package_type}/{package_name}/versions/{package_version_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("org", Var (params.org, String));
           ("package_version_id", Var (params.package_version_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_package_version_for_organization = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      org : string;
      package_name : string;
      package_type : Package_type.t;
      package_version_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package_version.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/packages/{package_type}/{package_name}/versions/{package_version_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("org", Var (params.org, String));
           ("package_version_id", Var (params.package_version_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Restore_package_version_for_org = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      org : string;
      package_name : string;
      package_type : Package_type.t;
      package_version_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url =
    "/orgs/{org}/packages/{package_type}/{package_name}/versions/{package_version_id}/restore"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("org", Var (params.org, String));
           ("package_version_id", Var (params.package_version_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_packages_for_authenticated_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Visibility = struct
      let t_of_yojson = function
        | `String "public" -> Ok "public"
        | `String "private" -> Ok "private"
        | `String "internal" -> Ok "internal"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_type : Package_type.t;
      visibility : Visibility.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/user/packages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("visibility", Var (params.visibility, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_package_for_authenticated_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/packages/{package_type}/{package_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_package_for_authenticated_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/user/packages/{package_type}/{package_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Restore_package_for_authenticated_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      token : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/packages/{package_type}/{package_name}/restore"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("token", Var (params.token, Option String)) ])
      ~url
      ~responses:Responses.t
      `Post
end

module Get_all_package_versions_for_package_owned_by_authenticated_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module State = struct
      let t_of_yojson = function
        | `String "active" -> Ok "active"
        | `String "deleted" -> Ok "deleted"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      page : int; [@default 1]
      per_page : int; [@default 30]
      state : State.t; [@default "active"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package_version.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
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

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/packages/{package_type}/{package_name}/versions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("state", Var (params.state, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_package_version_for_authenticated_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      package_version_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/packages/{package_type}/{package_name}/versions/{package_version_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("package_version_id", Var (params.package_version_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_package_version_for_authenticated_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      package_version_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package_version.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/user/packages/{package_type}/{package_name}/versions/{package_version_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("package_version_id", Var (params.package_version_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Restore_package_version_for_authenticated_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      package_version_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/user/packages/{package_type}/{package_name}/versions/{package_version_id}/restore"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("package_version_id", Var (params.package_version_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module List_packages_for_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Visibility = struct
      let t_of_yojson = function
        | `String "public" -> Ok "public"
        | `String "private" -> Ok "private"
        | `String "internal" -> Ok "internal"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_type : Package_type.t;
      username : string;
      visibility : Visibility.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
      ]
  end

  let url = "/users/{username}/packages"

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
           ("package_type", Var (params.package_type, String));
           ("visibility", Var (params.visibility, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_package_for_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      username : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/users/{username}/packages/{package_type}/{package_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("username", Var (params.username, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_package_for_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      username : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/users/{username}/packages/{package_type}/{package_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("username", Var (params.username, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Restore_package_for_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      token : string option; [@default None]
      username : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/users/{username}/packages/{package_type}/{package_name}/restore"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("username", Var (params.username, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("token", Var (params.token, Option String)) ])
      ~url
      ~responses:Responses.t
      `Post
end

module Get_all_package_versions_for_package_owned_by_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      username : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package_version.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unauthorized = struct
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

    type t =
      [ `OK of OK.t
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/users/{username}/packages/{package_type}/{package_name}/versions"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("username", Var (params.username, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Delete_package_version_for_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      package_version_id : int;
      username : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url = "/users/{username}/packages/{package_type}/{package_name}/versions/{package_version_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("username", Var (params.username, String));
           ("package_version_id", Var (params.package_version_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module Get_package_version_for_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      package_version_id : int;
      username : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Package_version.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/users/{username}/packages/{package_type}/{package_name}/versions/{package_version_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("package_version_id", Var (params.package_version_id, Int));
           ("username", Var (params.username, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module Restore_package_version_for_user = struct
  module Parameters = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      package_name : string;
      package_type : Package_type.t;
      package_version_id : int;
      username : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    module Unauthorized = struct
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

    type t =
      [ `No_content
      | `Unauthorized of Unauthorized.t
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("401", Openapi.of_json_body (fun v -> `Unauthorized v) Unauthorized.of_yojson);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
      ]
  end

  let url =
    "/users/{username}/packages/{package_type}/{package_name}/versions/{package_version_id}/restore"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_type", Var (params.package_type, String));
           ("package_name", Var (params.package_name, String));
           ("username", Var (params.username, String));
           ("package_version_id", Var (params.package_version_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end
