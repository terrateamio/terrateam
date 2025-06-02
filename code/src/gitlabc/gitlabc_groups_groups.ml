module GetApiV4GroupsIdGroupsShared = struct
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
      id : string;
      min_access_level : int option; [@default None]
      order_by : Order_by.t; [@default "name"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      search : string option; [@default None]
      skip_groups : Skip_groups.t option; [@default None]
      sort : Sort.t; [@default "asc"]
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

  let url = "/api/v4/groups/{id}/groups/shared"

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
           ("skip_groups", Var (params.skip_groups, Option (Array Int)));
           ("visibility", Var (params.visibility, Option String));
           ("search", Var (params.search, Option String));
           ("min_access_level", Var (params.min_access_level, Option Int));
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
