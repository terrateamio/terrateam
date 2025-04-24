module Get_route_stats_by_actor = struct
  module Parameters = struct
    module Actor_type = struct
      let t_of_yojson = function
        | `String "installation" -> Ok "installation"
        | `String "classic_pat" -> Ok "classic_pat"
        | `String "fine_grained_pat" -> Ok "fine_grained_pat"
        | `String "oauth_app" -> Ok "oauth_app"
        | `String "github_app_user_to_server" -> Ok "github_app_user_to_server"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Direction = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      module Items = struct
        let t_of_yojson = function
          | `String "last_rate_limited_timestamp" -> Ok "last_rate_limited_timestamp"
          | `String "last_request_timestamp" -> Ok "last_request_timestamp"
          | `String "rate_limited_request_count" -> Ok "rate_limited_request_count"
          | `String "http_method" -> Ok "http_method"
          | `String "api_route" -> Ok "api_route"
          | `String "total_request_count" -> Ok "total_request_count"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
      end

      type t = Items.t list [@@deriving show, eq]
    end

    type t = {
      actor_id : int;
      actor_type : Actor_type.t;
      api_route_substring : string option; [@default None]
      direction : Direction.t; [@default "desc"]
      max_timestamp : string option; [@default None]
      min_timestamp : string;
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      sort : Sort.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Api_insights_route_stats.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/insights/api/route-stats/{actor_type}/{actor_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("org", Var (params.org, String));
           ("actor_type", Var (params.actor_type, String));
           ("actor_id", Var (params.actor_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("min_timestamp", Var (params.min_timestamp, String));
           ("max_timestamp", Var (params.max_timestamp, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("direction", Var (params.direction, String));
           ("sort", Var (params.sort, Option (Array String)));
           ("api_route_substring", Var (params.api_route_substring, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_subject_stats = struct
  module Parameters = struct
    module Direction = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      module Items = struct
        let t_of_yojson = function
          | `String "last_rate_limited_timestamp" -> Ok "last_rate_limited_timestamp"
          | `String "last_request_timestamp" -> Ok "last_request_timestamp"
          | `String "rate_limited_request_count" -> Ok "rate_limited_request_count"
          | `String "subject_name" -> Ok "subject_name"
          | `String "total_request_count" -> Ok "total_request_count"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
      end

      type t = Items.t list [@@deriving show, eq]
    end

    type t = {
      direction : Direction.t; [@default "desc"]
      max_timestamp : string option; [@default None]
      min_timestamp : string;
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      sort : Sort.t option; [@default None]
      subject_name_substring : string option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Api_insights_subject_stats.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/insights/api/subject-stats"

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
           ("min_timestamp", Var (params.min_timestamp, String));
           ("max_timestamp", Var (params.max_timestamp, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("direction", Var (params.direction, String));
           ("sort", Var (params.sort, Option (Array String)));
           ("subject_name_substring", Var (params.subject_name_substring, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_summary_stats = struct
  module Parameters = struct
    type t = {
      max_timestamp : string option; [@default None]
      min_timestamp : string;
      org : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Api_insights_summary_stats.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/insights/api/summary-stats"

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
           ("min_timestamp", Var (params.min_timestamp, String));
           ("max_timestamp", Var (params.max_timestamp, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_summary_stats_by_user = struct
  module Parameters = struct
    type t = {
      max_timestamp : string option; [@default None]
      min_timestamp : string;
      org : string;
      user_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Api_insights_summary_stats.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/insights/api/summary-stats/users/{user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("org", Var (params.org, String)); ("user_id", Var (params.user_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("min_timestamp", Var (params.min_timestamp, String));
           ("max_timestamp", Var (params.max_timestamp, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_summary_stats_by_actor = struct
  module Parameters = struct
    module Actor_type = struct
      let t_of_yojson = function
        | `String "installation" -> Ok "installation"
        | `String "classic_pat" -> Ok "classic_pat"
        | `String "fine_grained_pat" -> Ok "fine_grained_pat"
        | `String "oauth_app" -> Ok "oauth_app"
        | `String "github_app_user_to_server" -> Ok "github_app_user_to_server"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      actor_id : int;
      actor_type : Actor_type.t;
      max_timestamp : string option; [@default None]
      min_timestamp : string;
      org : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Api_insights_summary_stats.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/insights/api/summary-stats/{actor_type}/{actor_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("org", Var (params.org, String));
           ("actor_type", Var (params.actor_type, String));
           ("actor_id", Var (params.actor_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("min_timestamp", Var (params.min_timestamp, String));
           ("max_timestamp", Var (params.max_timestamp, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_time_stats = struct
  module Parameters = struct
    type t = {
      max_timestamp : string option; [@default None]
      min_timestamp : string;
      org : string;
      timestamp_increment : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Api_insights_time_stats.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/insights/api/time-stats"

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
           ("min_timestamp", Var (params.min_timestamp, String));
           ("max_timestamp", Var (params.max_timestamp, Option String));
           ("timestamp_increment", Var (params.timestamp_increment, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_time_stats_by_user = struct
  module Parameters = struct
    type t = {
      max_timestamp : string option; [@default None]
      min_timestamp : string;
      org : string;
      timestamp_increment : string;
      user_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Api_insights_time_stats.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/insights/api/time-stats/users/{user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("org", Var (params.org, String)); ("user_id", Var (params.user_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("min_timestamp", Var (params.min_timestamp, String));
           ("max_timestamp", Var (params.max_timestamp, Option String));
           ("timestamp_increment", Var (params.timestamp_increment, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_time_stats_by_actor = struct
  module Parameters = struct
    module Actor_type = struct
      let t_of_yojson = function
        | `String "installation" -> Ok "installation"
        | `String "classic_pat" -> Ok "classic_pat"
        | `String "fine_grained_pat" -> Ok "fine_grained_pat"
        | `String "oauth_app" -> Ok "oauth_app"
        | `String "github_app_user_to_server" -> Ok "github_app_user_to_server"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      actor_id : int;
      actor_type : Actor_type.t;
      max_timestamp : string option; [@default None]
      min_timestamp : string;
      org : string;
      timestamp_increment : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Api_insights_time_stats.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/insights/api/time-stats/{actor_type}/{actor_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("org", Var (params.org, String));
           ("actor_type", Var (params.actor_type, String));
           ("actor_id", Var (params.actor_id, Int));
         ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("min_timestamp", Var (params.min_timestamp, String));
           ("max_timestamp", Var (params.max_timestamp, Option String));
           ("timestamp_increment", Var (params.timestamp_increment, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Get_user_stats = struct
  module Parameters = struct
    module Direction = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      module Items = struct
        let t_of_yojson = function
          | `String "last_rate_limited_timestamp" -> Ok "last_rate_limited_timestamp"
          | `String "last_request_timestamp" -> Ok "last_request_timestamp"
          | `String "rate_limited_request_count" -> Ok "rate_limited_request_count"
          | `String "subject_name" -> Ok "subject_name"
          | `String "total_request_count" -> Ok "total_request_count"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
      end

      type t = Items.t list [@@deriving show, eq]
    end

    type t = {
      actor_name_substring : string option; [@default None]
      direction : Direction.t; [@default "desc"]
      max_timestamp : string option; [@default None]
      min_timestamp : string;
      org : string;
      page : int; [@default 1]
      per_page : int; [@default 30]
      sort : Sort.t option; [@default None]
      user_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      type t = Githubc2_components.Api_insights_user_stats.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t = [ `OK of OK.t ] [@@deriving show, eq]

    let t = [ ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson) ]
  end

  let url = "/orgs/{org}/insights/api/user-stats/{user_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("org", Var (params.org, String)); ("user_id", Var (params.user_id, String)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("min_timestamp", Var (params.min_timestamp, String));
           ("max_timestamp", Var (params.max_timestamp, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("direction", Var (params.direction, String));
           ("sort", Var (params.sort, Option (Array String)));
           ("actor_name_substring", Var (params.actor_name_substring, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
