module GetApiV4GroupsIdProjects = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "id" -> Ok "id"
        | `String "name" -> Ok "name"
        | `String "path" -> Ok "path"
        | `String "created_at" -> Ok "created_at"
        | `String "updated_at" -> Ok "updated_at"
        | `String "last_activity_at" -> Ok "last_activity_at"
        | `String "similarity" -> Ok "similarity"
        | `String "star_count" -> Ok "star_count"
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

    module Visibility = struct
      let t_of_yojson = function
        | `String "private" -> Ok "private"
        | `String "internal" -> Ok "internal"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      archived : bool option; [@default None]
      id : string;
      include_ancestor_groups : bool; [@default false]
      include_subgroups : bool; [@default false]
      min_access_level : int option; [@default None]
      order_by : Order_by.t; [@default "created_at"]
      owned : bool; [@default false]
      page : int; [@default 1]
      per_page : int; [@default 20]
      search : string option; [@default None]
      simple : bool; [@default false]
      sort : Sort.t; [@default "desc"]
      starred : bool; [@default false]
      visibility : Visibility.t option; [@default None]
      with_custom_attributes : bool; [@default false]
      with_issues_enabled : bool; [@default false]
      with_merge_requests_enabled : bool; [@default false]
      with_security_reports : bool; [@default false]
      with_shared : bool; [@default true]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/groups/{id}/projects"

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
           ("archived", Var (params.archived, Option Bool));
           ("visibility", Var (params.visibility, Option String));
           ("search", Var (params.search, Option String));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("simple", Var (params.simple, Bool));
           ("owned", Var (params.owned, Bool));
           ("starred", Var (params.starred, Bool));
           ("with_issues_enabled", Var (params.with_issues_enabled, Bool));
           ("with_merge_requests_enabled", Var (params.with_merge_requests_enabled, Bool));
           ("with_shared", Var (params.with_shared, Bool));
           ("include_subgroups", Var (params.include_subgroups, Bool));
           ("include_ancestor_groups", Var (params.include_ancestor_groups, Bool));
           ("min_access_level", Var (params.min_access_level, Option Int));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
           ("with_security_reports", Var (params.with_security_reports, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4GroupsIdProjectsShared = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "id" -> Ok "id"
        | `String "name" -> Ok "name"
        | `String "path" -> Ok "path"
        | `String "created_at" -> Ok "created_at"
        | `String "updated_at" -> Ok "updated_at"
        | `String "last_activity_at" -> Ok "last_activity_at"
        | `String "star_count" -> Ok "star_count"
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

    module Visibility = struct
      let t_of_yojson = function
        | `String "private" -> Ok "private"
        | `String "internal" -> Ok "internal"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      archived : bool option; [@default None]
      id : string;
      min_access_level : int option; [@default None]
      order_by : Order_by.t; [@default "created_at"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      search : string option; [@default None]
      simple : bool; [@default false]
      sort : Sort.t; [@default "desc"]
      starred : bool; [@default false]
      visibility : Visibility.t option; [@default None]
      with_custom_attributes : bool; [@default false]
      with_issues_enabled : bool; [@default false]
      with_merge_requests_enabled : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/groups/{id}/projects/shared"

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
           ("archived", Var (params.archived, Option Bool));
           ("visibility", Var (params.visibility, Option String));
           ("search", Var (params.search, Option String));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("simple", Var (params.simple, Bool));
           ("starred", Var (params.starred, Bool));
           ("with_issues_enabled", Var (params.with_issues_enabled, Bool));
           ("with_merge_requests_enabled", Var (params.with_merge_requests_enabled, Bool));
           ("min_access_level", Var (params.min_access_level, Option Int));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4GroupsIdProjectsProjectId = struct
  module Parameters = struct
    type t = {
      id : string;
      project_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/groups/{id}/projects/{project_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, String)); ("project_id", Var (params.project_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end
