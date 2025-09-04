module PostApiV4Groups = struct
  module Parameters = struct end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4Groups.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/groups"

  let make ?body =
   fun () ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4Groups = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "name" -> Ok "name"
        | `String "path" -> Ok "path"
        | `String "id" -> Ok "id"
        | `String "similarity" -> Ok "similarity"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Skip_groups = struct
      type t = int list [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Visibility = struct
      let t_of_yojson = function
        | `String "private" -> Ok "private"
        | `String "internal" -> Ok "internal"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      all_available : bool option; [@default None]
      marked_for_deletion_on : string option; [@default None]
      min_access_level : int option; [@default None]
      order_by : Order_by.t; [@default "name"]
      owned : bool; [@default false]
      page : int; [@default 1]
      per_page : int; [@default 20]
      repository_storage : string option; [@default None]
      search : string option; [@default None]
      skip_groups : Skip_groups.t option; [@default None]
      sort : Sort.t; [@default "asc"]
      statistics : bool; [@default false]
      top_level_only : bool option; [@default None]
      visibility : Visibility.t option; [@default None]
      with_custom_attributes : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Gitlabc_components.API_Entities_Group.t list
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/api/v4/groups"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("statistics", Var (params.statistics, Bool));
           ("skip_groups", Var (params.skip_groups, Option (Array Int)));
           ("all_available", Var (params.all_available, Option Bool));
           ("visibility", Var (params.visibility, Option String));
           ("search", Var (params.search, Option String));
           ("owned", Var (params.owned, Bool));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("min_access_level", Var (params.min_access_level, Option Int));
           ("top_level_only", Var (params.top_level_only, Option Bool));
           ("repository_storage", Var (params.repository_storage, Option String));
           ("marked_for_deletion_on", Var (params.marked_for_deletion_on, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4GroupsImport = struct
  module Parameters = struct
    type t = {
      file : string;
      name : string;
      organization_id : int option; [@default None]
      parent_id : int option; [@default None]
      path : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Service_unavailable = struct end

    type t =
      [ `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Service_unavailable
      ]
    [@@deriving show, eq]

    let t =
      [
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("503", fun _ -> Ok `Service_unavailable);
      ]
  end

  let url = "/api/v4/groups/import"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4GroupsImportAuthorize = struct
  module Parameters = struct end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/groups/import/authorize"

  let make () =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4GroupsId = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/groups/{id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4GroupsId = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PutApiV4GroupsId.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/groups/{id}"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4GroupsId = struct
  module Parameters = struct
    type t = {
      id : string;
      with_custom_attributes : bool; [@default false]
      with_projects : bool; [@default true]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Gitlabc_components.API_Entities_GroupDetail.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/api/v4/groups/{id}"

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
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
           ("with_projects", Var (params.with_projects, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4GroupsIdDebianDistributions = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PostApiV4GroupsIdDebianDistributions.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module Created = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Created
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("201", fun _ -> Ok `Created);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/debian_distributions"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4GroupsIdDebianDistributions = struct
  module Parameters = struct
    module Architectures = struct
      type t = string list [@@deriving show, eq]
    end

    module Components = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      architectures : Architectures.t option; [@default None]
      codename : string option; [@default None]
      components : Components.t option; [@default None]
      description : string option; [@default None]
      id : string;
      label : string option; [@default None]
      origin : string option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
      suite : string option; [@default None]
      valid_time_duration_seconds : int option; [@default None]
      version : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/debian_distributions"

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
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("codename", Var (params.codename, Option String));
           ("suite", Var (params.suite, Option String));
           ("origin", Var (params.origin, Option String));
           ("label", Var (params.label, Option String));
           ("version", Var (params.version, Option String));
           ("description", Var (params.description, Option String));
           ("valid_time_duration_seconds", Var (params.valid_time_duration_seconds, Option Int));
           ("components", Var (params.components, Option (Array String)));
           ("architectures", Var (params.architectures, Option (Array String)));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4GroupsIdDebianDistributionsCodename = struct
  module Parameters = struct
    module Architectures = struct
      type t = string list [@@deriving show, eq]
    end

    module Components = struct
      type t = string list [@@deriving show, eq]
    end

    type t = {
      architectures : Architectures.t option; [@default None]
      codename : string;
      components : Components.t option; [@default None]
      description : string option; [@default None]
      id : string;
      label : string option; [@default None]
      origin : string option; [@default None]
      suite : string option; [@default None]
      valid_time_duration_seconds : int option; [@default None]
      version : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/debian_distributions/{codename}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("codename", Var (params.codename, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("suite", Var (params.suite, Option String));
           ("origin", Var (params.origin, Option String));
           ("label", Var (params.label, Option String));
           ("version", Var (params.version, Option String));
           ("description", Var (params.description, Option String));
           ("valid_time_duration_seconds", Var (params.valid_time_duration_seconds, Option Int));
           ("components", Var (params.components, Option (Array String)));
           ("architectures", Var (params.architectures, Option (Array String)));
         ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4GroupsIdDebianDistributionsCodename = struct
  module Parameters = struct
    type t = {
      codename : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PutApiV4GroupsIdDebianDistributionsCodename.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/debian_distributions/{codename}"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("codename", Var (params.codename, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4GroupsIdDebianDistributionsCodename = struct
  module Parameters = struct
    type t = {
      codename : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/debian_distributions/{codename}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("codename", Var (params.codename, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdDebianDistributionsCodenameKeyAsc = struct
  module Parameters = struct
    type t = {
      codename : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/debian_distributions/{codename}/key.asc"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("codename", Var (params.codename, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesDebianDists_distributionInrelease = struct
  module Parameters = struct
    type t = {
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/debian/dists/*distribution/InRelease"

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
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesDebianDists_distributionRelease = struct
  module Parameters = struct
    type t = {
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/debian/dists/*distribution/Release"

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
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesDebianDists_distributionReleaseGpg = struct
  module Parameters = struct
    type t = {
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/debian/dists/*distribution/Release.gpg"

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
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesDebianDists_distributionComponentBinaryArchitecturePackages = struct
  module Parameters = struct
    type t = {
      architecture : string;
      component : string;
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/groups/{id}/-/packages/debian/dists/*distribution/{component}/binary-{architecture}/Packages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("component", Var (params.component, String));
           ("architecture", Var (params.architecture, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4GroupsIdPackagesDebianDists_distributionComponentBinaryArchitectureByHashSha256FileSha256 =
struct
  module Parameters = struct
    type t = {
      architecture : string;
      component : string;
      distribution : string;
      file_sha256 : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/groups/{id}/-/packages/debian/dists/*distribution/{component}/binary-{architecture}/by-hash/SHA256/{file_sha256}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("component", Var (params.component, String));
           ("architecture", Var (params.architecture, String));
           ("file_sha256", Var (params.file_sha256, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4GroupsIdPackagesDebianDists_distributionComponentDebianInstallerBinaryArchitecturePackages =
struct
  module Parameters = struct
    type t = {
      architecture : string;
      component : string;
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/groups/{id}/-/packages/debian/dists/*distribution/{component}/debian-installer/binary-{architecture}/Packages"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("component", Var (params.component, String));
           ("architecture", Var (params.architecture, String));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4GroupsIdPackagesDebianDists_distributionComponentDebianInstallerBinaryArchitectureByHashSha256FileSha256 =
struct
  module Parameters = struct
    type t = {
      architecture : string;
      component : string;
      distribution : string;
      file_sha256 : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/groups/{id}/-/packages/debian/dists/*distribution/{component}/debian-installer/binary-{architecture}/by-hash/SHA256/{file_sha256}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("component", Var (params.component, String));
           ("architecture", Var (params.architecture, String));
           ("file_sha256", Var (params.file_sha256, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesDebianDists_distributionComponentSourceSources = struct
  module Parameters = struct
    type t = {
      component : string;
      distribution : string;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/debian/dists/*distribution/{component}/source/Sources"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("component", Var (params.component, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesDebianDists_distributionComponentSourceByHashSha256FileSha256 =
struct
  module Parameters = struct
    type t = {
      component : string;
      distribution : string;
      file_sha256 : int;
      id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Accepted = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Accepted
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("202", fun _ -> Ok `Accepted);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/groups/{id}/-/packages/debian/dists/*distribution/{component}/source/by-hash/SHA256/{file_sha256}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("component", Var (params.component, String));
           ("file_sha256", Var (params.file_sha256, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("distribution", Var (params.distribution, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module
  GetApiV4GroupsIdPackagesDebianPoolDistributionProjectIdLetterPackageNamePackageVersionFileName =
struct
  module Parameters = struct
    type t = {
      distribution : string;
      file_name : string;
      id : string;
      letter : string;
      package_name : string;
      package_version : string;
      project_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url =
    "/api/v4/groups/{id}/-/packages/debian/pool/{distribution}/{project_id}/{letter}/{package_name}/{package_version}/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("id", Var (params.id, String));
           ("project_id", Var (params.project_id, Int));
           ("distribution", Var (params.distribution, String));
           ("letter", Var (params.letter, String));
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
           ("file_name", Var (params.file_name, String));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesMaven_pathFileName = struct
  module Parameters = struct
    type t = {
      file_name : string;
      id : string;
      path : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Found = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Found
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("302", fun _ -> Ok `Found);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/maven/*path/{file_name}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("file_name", Var (params.file_name, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("path", Var (params.path, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesNpm_packageName = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Found = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Found
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("302", fun _ -> Ok `Found);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/npm/*package_name"

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
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4GroupsIdPackagesNpmNpmV1SecurityAdvisoriesBulk = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Temporary_redirect = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Temporary_redirect
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("307", fun _ -> Ok `Temporary_redirect);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/npm/-/npm/v1/security/advisories/bulk"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module PostApiV4GroupsIdPackagesNpmNpmV1SecurityAuditsQuick = struct
  module Parameters = struct
    type t = { id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Temporary_redirect = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Temporary_redirect
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("307", fun _ -> Ok `Temporary_redirect);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/npm/-/npm/v1/security/audits/quick"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4GroupsIdPackagesNpmPackage_packageNameDistTags = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/npm/-/package/*package_name/dist-tags"

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
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4GroupsIdPackagesNpmPackage_packageNameDistTagsTag = struct
  module Parameters = struct
    type t = {
      id : string;
      package_name : string;
      tag : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/npm/-/package/*package_name/dist-tags/{tag}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag", Var (params.tag, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4GroupsIdPackagesNpmPackage_packageNameDistTagsTag = struct
  module Parameters = struct
    type t = {
      id : string;
      tag : string;
    }
    [@@deriving make, show, eq]
  end

  module Request_body = struct
    type t = Gitlabc_components.PutApiV4GroupsIdPackagesNpmPackage_packageNameDistTagsTag.t
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Responses = struct
    module No_content = struct end
    module Bad_request = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `No_content
      | `Bad_request
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("204", fun _ -> Ok `No_content);
        ("400", fun _ -> Ok `Bad_request);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/npm/-/package/*package_name/dist-tags/{tag}"

  let make ?body =
   fun params ->
    Openapi.Request.make
      ?body:(CCOption.map Request_body.to_yojson body)
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("tag", Var (params.tag, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4GroupsIdPackagesNugetIndex = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/groups/{id}/-/packages/nuget/index"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesNugetMetadata_packageName_packageVersion = struct
  module Parameters = struct
    type t = {
      id : int;
      package_name : string;
      package_version : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/nuget/metadata/*package_name/*package_version"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("package_name", Var (params.package_name, String));
           ("package_version", Var (params.package_version, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesNugetMetadata_packageNameIndex = struct
  module Parameters = struct
    type t = {
      id : int;
      package_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/nuget/metadata/*package_name/index"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesNugetQuery = struct
  module Parameters = struct
    type t = {
      id : int;
      prerelease : bool; [@default true]
      q : string option; [@default None]
      skip : int; [@default 0]
      take : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/nuget/query"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("q", Var (params.q, Option String));
           ("skip", Var (params.skip, Int));
           ("take", Var (params.take, Int));
           ("prerelease", Var (params.prerelease, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesNugetSymbolfiles_fileName_signature_sameFileName = struct
  module Parameters = struct
    type t = {
      symbolchecksum : string; [@key "Symbolchecksum"]
      file_name : string;
      id : int;
      same_file_name : string;
      signature : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Bad_request = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Bad_request
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("400", fun _ -> Ok `Bad_request);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/nuget/symbolfiles/*file_name/*signature/*same_file_name"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("file_name", Var (params.file_name, String));
           ("signature", Var (params.signature, String));
           ("same_file_name", Var (params.same_file_name, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesNugetV2 = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Not_found
      ]
    [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK); ("404", fun _ -> Ok `Not_found) ]
  end

  let url = "/api/v4/groups/{id}/-/packages/nuget/v2"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesNugetV2_metadata = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/groups/{id}/-/packages/nuget/v2/$metadata"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesPypiFilesSha256_fileIdentifier = struct
  module Parameters = struct
    type t = {
      file_identifier : string;
      id : int;
      sha256 : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/pypi/files/{sha256}/*file_identifier"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("sha256", Var (params.sha256, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("file_identifier", Var (params.file_identifier, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesPypiSimple = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/pypi/simple"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdPackagesPypiSimple_packageName = struct
  module Parameters = struct
    type t = {
      id : int;
      package_name : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end
    module Unauthorized = struct end
    module Forbidden = struct end
    module Not_found = struct end

    type t =
      [ `OK
      | `Unauthorized
      | `Forbidden
      | `Not_found
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", fun _ -> Ok `OK);
        ("401", fun _ -> Ok `Unauthorized);
        ("403", fun _ -> Ok `Forbidden);
        ("404", fun _ -> Ok `Not_found);
      ]
  end

  let url = "/api/v4/groups/{id}/-/packages/pypi/simple/*package_name"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("package_name", Var (params.package_name, String)) ])
      ~url
      ~responses:Responses.t
      `Get
end
