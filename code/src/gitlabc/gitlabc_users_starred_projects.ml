module GetApiV4UsersUserIdStarredProjects = struct
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
        | `String "storage_size" -> Ok "storage_size"
        | `String "repository_size" -> Ok "repository_size"
        | `String "wiki_size" -> Ok "wiki_size"
        | `String "packages_size" -> Ok "packages_size"
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

    module Topic = struct
      type t = string list [@@deriving show, eq]
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
      order_by : Order_by.t; [@default "created_at"]
      owned : bool; [@default false]
      page : int; [@default 1]
      per_page : int; [@default 20]
      repository_checksum_failed : bool; [@default false]
      repository_storage : string option; [@default None]
      search : string option; [@default None]
      search_namespaces : bool option; [@default None]
      simple : bool; [@default false]
      sort : Sort.t; [@default "desc"]
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
           ("order_by", Var (params.order_by, String));
           ("sort", Var (params.sort, String));
           ("archived", Var (params.archived, Option Bool));
           ("visibility", Var (params.visibility, Option String));
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
