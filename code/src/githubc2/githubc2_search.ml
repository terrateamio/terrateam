module Code = struct
  module Parameters = struct
    module Order = struct
      let t_of_yojson = function
        | `String "desc" -> Ok "desc"
        | `String "asc" -> Ok "asc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "indexed" -> Ok "indexed"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      order : Order.t; [@default "desc"]
      page : int; [@default 1]
      per_page : int; [@default 30]
      q : string;
      sort : Sort.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Items = struct
          type t = Githubc2_components.Code_search_result_item.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          incomplete_results : bool;
          items : Items.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Service_unavailable = struct
      module Primary = struct
        type t = {
          code : string option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Unprocessable_entity of Unprocessable_entity.t
      | `Service_unavailable of Service_unavailable.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
        ("503", Openapi.of_json_body (fun v -> `Service_unavailable v) Service_unavailable.of_yojson);
      ]
  end

  let url = "/search/code"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("q", Var (params.q, String));
           ("sort", Var (params.sort, Option String));
           ("order", Var (params.order, String));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Commits = struct
  module Parameters = struct
    module Order = struct
      let t_of_yojson = function
        | `String "desc" -> Ok "desc"
        | `String "asc" -> Ok "asc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "author-date" -> Ok "author-date"
        | `String "committer-date" -> Ok "committer-date"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      order : Order.t; [@default "desc"]
      page : int; [@default 1]
      per_page : int; [@default 30]
      q : string;
      sort : Sort.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Items = struct
          type t = Githubc2_components.Commit_search_result_item.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          incomplete_results : bool;
          items : Items.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    type t =
      [ `OK of OK.t
      | `Not_modified
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
      ]
  end

  let url = "/search/commits"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("q", Var (params.q, String));
           ("sort", Var (params.sort, Option String));
           ("order", Var (params.order, String));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Issues_and_pull_requests = struct
  module Parameters = struct
    module Order = struct
      let t_of_yojson = function
        | `String "desc" -> Ok "desc"
        | `String "asc" -> Ok "asc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "comments" -> Ok "comments"
        | `String "reactions" -> Ok "reactions"
        | `String "reactions-+1" -> Ok "reactions-+1"
        | `String "reactions--1" -> Ok "reactions--1"
        | `String "reactions-smile" -> Ok "reactions-smile"
        | `String "reactions-thinking_face" -> Ok "reactions-thinking_face"
        | `String "reactions-heart" -> Ok "reactions-heart"
        | `String "reactions-tada" -> Ok "reactions-tada"
        | `String "interactions" -> Ok "interactions"
        | `String "created" -> Ok "created"
        | `String "updated" -> Ok "updated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      advanced_search : string option; [@default None]
      order : Order.t; [@default "desc"]
      page : int; [@default 1]
      per_page : int; [@default 30]
      q : string;
      sort : Sort.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Items = struct
          type t = Githubc2_components.Issue_search_result_item.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          incomplete_results : bool;
          items : Items.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Service_unavailable = struct
      module Primary = struct
        type t = {
          code : string option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Unprocessable_entity of Unprocessable_entity.t
      | `Service_unavailable of Service_unavailable.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
        ("503", Openapi.of_json_body (fun v -> `Service_unavailable v) Service_unavailable.of_yojson);
      ]
  end

  let url = "/search/issues"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("q", Var (params.q, String));
           ("sort", Var (params.sort, Option String));
           ("order", Var (params.order, String));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
           ("advanced_search", Var (params.advanced_search, Option String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Labels = struct
  module Parameters = struct
    module Order = struct
      let t_of_yojson = function
        | `String "desc" -> Ok "desc"
        | `String "asc" -> Ok "asc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "created" -> Ok "created"
        | `String "updated" -> Ok "updated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      order : Order.t; [@default "desc"]
      page : int; [@default 1]
      per_page : int; [@default 30]
      q : string;
      repository_id : int;
      sort : Sort.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Items = struct
          type t = Githubc2_components.Label_search_result_item.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          incomplete_results : bool;
          items : Items.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Forbidden = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Not_found = struct
      type t = Githubc2_components.Basic_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Forbidden of Forbidden.t
      | `Not_found of Not_found.t
      | `Unprocessable_entity of Unprocessable_entity.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ("403", Openapi.of_json_body (fun v -> `Forbidden v) Forbidden.of_yojson);
        ("404", Openapi.of_json_body (fun v -> `Not_found v) Not_found.of_yojson);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
      ]
  end

  let url = "/search/labels"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("repository_id", Var (params.repository_id, Int));
           ("q", Var (params.q, String));
           ("sort", Var (params.sort, Option String));
           ("order", Var (params.order, String));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Repos = struct
  module Parameters = struct
    module Order = struct
      let t_of_yojson = function
        | `String "desc" -> Ok "desc"
        | `String "asc" -> Ok "asc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "stars" -> Ok "stars"
        | `String "forks" -> Ok "forks"
        | `String "help-wanted-issues" -> Ok "help-wanted-issues"
        | `String "updated" -> Ok "updated"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      order : Order.t; [@default "desc"]
      page : int; [@default 1]
      per_page : int; [@default 30]
      q : string;
      sort : Sort.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Items = struct
          type t = Githubc2_components.Repo_search_result_item.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          incomplete_results : bool;
          items : Items.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Service_unavailable = struct
      module Primary = struct
        type t = {
          code : string option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unprocessable_entity of Unprocessable_entity.t
      | `Service_unavailable of Service_unavailable.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
        ("503", Openapi.of_json_body (fun v -> `Service_unavailable v) Service_unavailable.of_yojson);
      ]
  end

  let url = "/search/repositories"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("q", Var (params.q, String));
           ("sort", Var (params.sort, Option String));
           ("order", Var (params.order, String));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Topics = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 30]
      q : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Items = struct
          type t = Githubc2_components.Topic_search_result_item.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          incomplete_results : bool;
          items : Items.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    type t =
      [ `OK of OK.t
      | `Not_modified
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
      ]
  end

  let url = "/search/topics"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("q", Var (params.q, String));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module Users = struct
  module Parameters = struct
    module Order = struct
      let t_of_yojson = function
        | `String "desc" -> Ok "desc"
        | `String "asc" -> Ok "asc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Sort = struct
      let t_of_yojson = function
        | `String "followers" -> Ok "followers"
        | `String "repositories" -> Ok "repositories"
        | `String "joined" -> Ok "joined"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      order : Order.t; [@default "desc"]
      page : int; [@default 1]
      per_page : int; [@default 30]
      q : string;
      sort : Sort.t option; [@default None]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct
      module Primary = struct
        module Items = struct
          type t = Githubc2_components.User_search_result_item.t list
          [@@deriving yojson { strict = false; meta = false }, show, eq]
        end

        type t = {
          incomplete_results : bool;
          items : Items.t;
          total_count : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Not_modified = struct end

    module Unprocessable_entity = struct
      type t = Githubc2_components.Validation_error.t
      [@@deriving yojson { strict = false; meta = false }, show, eq]
    end

    module Service_unavailable = struct
      module Primary = struct
        type t = {
          code : string option; [@default None]
          documentation_url : string option; [@default None]
          message : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t =
      [ `OK of OK.t
      | `Not_modified
      | `Unprocessable_entity of Unprocessable_entity.t
      | `Service_unavailable of Service_unavailable.t
      ]
    [@@deriving show, eq]

    let t =
      [
        ("200", Openapi.of_json_body (fun v -> `OK v) OK.of_yojson);
        ("304", fun _ -> Ok `Not_modified);
        ( "422",
          Openapi.of_json_body (fun v -> `Unprocessable_entity v) Unprocessable_entity.of_yojson );
        ("503", Openapi.of_json_body (fun v -> `Service_unavailable v) Service_unavailable.of_yojson);
      ]
  end

  let url = "/search/users"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("q", Var (params.q, String));
           ("sort", Var (params.sort, Option String));
           ("order", Var (params.order, String));
           ("per_page", Var (params.per_page, Int));
           ("page", Var (params.page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end
