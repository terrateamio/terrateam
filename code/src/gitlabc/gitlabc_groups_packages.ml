module GetApiV4GroupsIdPackages = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "created_at" -> Ok "created_at"
        | `String "name" -> Ok "name"
        | `String "version" -> Ok "version"
        | `String "type" -> Ok "type"
        | `String "project_path" -> Ok "project_path"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Package_type = struct
      let t_of_yojson = function
        | `String "maven" -> Ok "maven"
        | `String "npm" -> Ok "npm"
        | `String "conan" -> Ok "conan"
        | `String "nuget" -> Ok "nuget"
        | `String "pypi" -> Ok "pypi"
        | `String "composer" -> Ok "composer"
        | `String "generic" -> Ok "generic"
        | `String "golang" -> Ok "golang"
        | `String "debian" -> Ok "debian"
        | `String "rubygems" -> Ok "rubygems"
        | `String "helm" -> Ok "helm"
        | `String "terraform_module" -> Ok "terraform_module"
        | `String "rpm" -> Ok "rpm"
        | `String "ml_model" -> Ok "ml_model"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Status = struct
      let t_of_yojson = function
        | `String "default" -> Ok "default"
        | `String "hidden" -> Ok "hidden"
        | `String "processing" -> Ok "processing"
        | `String "error" -> Ok "error"
        | `String "pending_destruction" -> Ok "pending_destruction"
        | `String "deprecated" -> Ok "deprecated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      exclude_subgroups : bool; [@default false]
      id : string;
      include_versionless : bool option; [@default None]
      order_by : Order_by.t; [@default "created_at"]
      package_name : string option; [@default None]
      package_type : Package_type.t option; [@default None]
      package_version : string option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
      sort : Sort.t; [@default "asc"]
      status : Status.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK); ("401", fun _ -> Ok `Unauthorized); ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/packages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("exclude_subgroups", Var (params.exclude_subgroups, Bool));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("package_type", Var (params.package_type, Option String));
           ("package_name", Var (params.package_name, Option String));
           ("package_version", Var (params.package_version, Option String));
           ("include_versionless", Var (params.include_versionless, Option Bool));
           ("status", Var (params.status, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
