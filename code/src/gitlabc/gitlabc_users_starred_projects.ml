module GetApiV4UsersUserIdStarredProjects = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "created_at" -> Ok `Created_at
        | `String "id" -> Ok `Id
        | `String "last_activity_at" -> Ok `Last_activity_at
        | `String "name" -> Ok `Name
        | `String "packages_size" -> Ok `Packages_size
        | `String "path" -> Ok `Path
        | `String "repository_size" -> Ok `Repository_size
        | `String "similarity" -> Ok `Similarity
        | `String "star_count" -> Ok `Star_count
        | `String "storage_size" -> Ok `Storage_size
        | `String "updated_at" -> Ok `Updated_at
        | `String "wiki_size" -> Ok `Wiki_size
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Created_at -> `String "created_at"
        | `Id -> `String "id"
        | `Last_activity_at -> `String "last_activity_at"
        | `Name -> `String "name"
        | `Packages_size -> `String "packages_size"
        | `Path -> `String "path"
        | `Repository_size -> `String "repository_size"
        | `Similarity -> `String "similarity"
        | `Star_count -> `String "star_count"
        | `Storage_size -> `String "storage_size"
        | `Updated_at -> `String "updated_at"
        | `Wiki_size -> `String "wiki_size"

      type t =
        ([ `Created_at
         | `Id
         | `Last_activity_at
         | `Name
         | `Packages_size
         | `Path
         | `Repository_size
         | `Similarity
         | `Star_count
         | `Storage_size
         | `Updated_at
         | `Wiki_size
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok `Asc
        | `String "desc" -> Ok `Desc
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Asc -> `String "asc"
        | `Desc -> `String "desc"

      type t =
        ([ `Asc
         | `Desc
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving show, eq]
    end

    module Topic = struct
      type t = string list [@@deriving show, eq]
    end

    module Visibility = struct
      let t_of_yojson = function
        | `String "internal" -> Ok `Internal
        | `String "private" -> Ok `Private
        | `String "public" -> Ok `Public
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Internal -> `String "internal"
        | `Private -> `String "private"
        | `Public -> `String "public"

      type t =
        ([ `Internal
         | `Private
         | `Public
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving show, eq]
    end

    type t = {
      archived : bool option; [@default None]
      id_after : int option; [@default None]
      id_before : int option; [@default None]
      imported : bool; [@default false]
      include_hidden : bool; [@default false]
      include_pending_delete : bool option; [@default None]
      last_activity_after : string option; [@default None]
      last_activity_before : string option; [@default None]
      marked_for_deletion_on : string option; [@default None]
      membership : bool; [@default false]
      min_access_level : int option; [@default None]
      order_by : Order_by.t; [@default `Created_at]
      owned : bool; [@default false]
      page : int; [@default 1]
      per_page : int; [@default 20]
      repository_checksum_failed : bool; [@default false]
      repository_storage : string option; [@default None]
      search : string option; [@default None]
      search_namespaces : bool option; [@default None]
      simple : bool; [@default false]
      sort : Sort.t; [@default `Desc]
      starred : bool; [@default false]
      statistics : bool; [@default false]
      topic : Topic.t option; [@default None]
      topic_id : int option; [@default None]
      updated_after : string option; [@default None]
      updated_before : string option; [@default None]
      user_id : string;
      visibility : Visibility.t option; [@default None]
      wiki_checksum_failed : bool; [@default false]
      with_issues_enabled : bool; [@default false]
      with_merge_requests_enabled : bool; [@default false]
      with_programming_language : string option; [@default None]
    }
    [@@deriving make, show, eq]
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

  let url = "/api/v4/users/{user_id}/starred_projects"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("order_by", Var (params.order_by, Enum Order_by.t_to_yojson));
           ("sort", Var (params.sort, Enum Sort.t_to_yojson));
           ("archived", Var (params.archived, Option Bool));
           ("visibility", Var (params.visibility, Option (Enum Visibility.t_to_yojson)));
           ("search", Var (params.search, Option String));
           ("search_namespaces", Var (params.search_namespaces, Option Bool));
           ("owned", Var (params.owned, Bool));
           ("starred", Var (params.starred, Bool));
           ("imported", Var (params.imported, Bool));
           ("membership", Var (params.membership, Bool));
           ("with_issues_enabled", Var (params.with_issues_enabled, Bool));
           ("with_merge_requests_enabled", Var (params.with_merge_requests_enabled, Bool));
           ("with_programming_language", Var (params.with_programming_language, Option String));
           ("min_access_level", Var (params.min_access_level, Option Int));
           ("id_after", Var (params.id_after, Option Int));
           ("id_before", Var (params.id_before, Option Int));
           ("last_activity_after", Var (params.last_activity_after, Option String));
           ("last_activity_before", Var (params.last_activity_before, Option String));
           ("repository_storage", Var (params.repository_storage, Option String));
           ("topic", Var (params.topic, Option (Array String)));
           ("topic_id", Var (params.topic_id, Option Int));
           ("updated_before", Var (params.updated_before, Option String));
           ("updated_after", Var (params.updated_after, Option String));
           ("include_pending_delete", Var (params.include_pending_delete, Option Bool));
           ("wiki_checksum_failed", Var (params.wiki_checksum_failed, Bool));
           ("repository_checksum_failed", Var (params.repository_checksum_failed, Bool));
           ("include_hidden", Var (params.include_hidden, Bool));
           ("marked_for_deletion_on", Var (params.marked_for_deletion_on, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("simple", Var (params.simple, Bool));
           ("statistics", Var (params.statistics, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
