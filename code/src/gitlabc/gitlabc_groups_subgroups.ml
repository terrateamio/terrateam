module GetApiV4GroupsIdSubgroups = struct
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
      id : string;
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
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/groups/{id}/subgroups"

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
