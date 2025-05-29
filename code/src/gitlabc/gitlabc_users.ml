module PostApiV4Users = struct
  module Parameters = struct
    type t = { postapiv4users : Gitlabc_components.PostApiV4Users.t [@key "postApiV4Users"] }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4Users = struct
  module Parameters = struct
    module Order_by = struct
      let t_of_yojson = function
        | `String "id" -> Ok "id"
        | `String "name" -> Ok "name"
        | `String "username" -> Ok "username"
        | `String "created_at" -> Ok "created_at"
        | `String "updated_at" -> Ok "updated_at"
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

    type t = {
      active : bool; [@default false]
      admins : bool; [@default false]
      auditors : bool; [@default false]
      blocked : bool; [@default false]
      created_after : string option; [@default None]
      created_before : string option; [@default None]
      exclude_active : bool; [@default false]
      exclude_external : bool; [@default false]
      exclude_humans : bool; [@default false]
      exclude_internal : bool; [@default false]
      extern_uid : string option; [@default None]
      external_ : bool; [@default false] [@key "external"]
      humans : bool; [@default false]
      order_by : Order_by.t option; [@default None]
      page : int; [@default 1]
      per_page : int; [@default 20]
      provider : string option; [@default None]
      saml_provider_id : int option; [@default None]
      search : string option; [@default None]
      skip_ldap : bool; [@default false]
      sort : Sort.t option; [@default None]
      two_factor : string option; [@default None]
      username : string option; [@default None]
      with_custom_attributes : bool; [@default false]
      without_project_bots : bool; [@default false]
      without_projects : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:[]
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("username", Var (params.username, Option String));
           ("extern_uid", Var (params.extern_uid, Option String));
           ("provider", Var (params.provider, Option String));
           ("search", Var (params.search, Option String));
           ("active", Var (params.active, Bool));
           ("humans", Var (params.humans, Bool));
           ("external", Var (params.external_, Bool));
           ("blocked", Var (params.blocked, Bool));
           ("created_after", Var (params.created_after, Option String));
           ("created_before", Var (params.created_before, Option String));
           ("without_projects", Var (params.without_projects, Bool));
           ("without_project_bots", Var (params.without_project_bots, Bool));
           ("admins", Var (params.admins, Bool));
           ("two_factor", Var (params.two_factor, Option String));
           ("exclude_active", Var (params.exclude_active, Bool));
           ("exclude_external", Var (params.exclude_external, Bool));
           ("exclude_humans", Var (params.exclude_humans, Bool));
           ("exclude_internal", Var (params.exclude_internal, Bool));
           ("order_by", Var (params.order_by, Option String));
           ("sort", Var (params.sort, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
           ("skip_ldap", Var (params.skip_ldap, Bool));
           ("saml_provider_id", Var (params.saml_provider_id, Option Int));
           ("auditors", Var (params.auditors, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4UsersId = struct
  module Parameters = struct
    type t = {
      hard_delete : bool option; [@default None]
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}"

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
         [ ("hard_delete", Var (params.hard_delete, Option Bool)) ])
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4UsersId = struct
  module Parameters = struct
    type t = {
      id : int;
      putapiv4usersid : Gitlabc_components.PutApiV4UsersId.t; [@key "putApiV4UsersId"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}"

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
      `Put
end

module GetApiV4UsersId = struct
  module Parameters = struct
    type t = {
      id : int;
      with_custom_attributes : bool; [@default false]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}"

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
         [ ("with_custom_attributes", Var (params.with_custom_attributes, Bool)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4UsersIdActivate = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/activate"

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
      `Post
end

module PostApiV4UsersIdApprove = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/approve"

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
      `Post
end

module GetApiV4UsersIdAssociationsCount = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/associations_count"

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

module PostApiV4UsersIdBan = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/ban"

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
      `Post
end

module PostApiV4UsersIdBlock = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/block"

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
      `Post
end

module GetApiV4UsersIdCustomAttributes = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/custom_attributes"

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

module DeleteApiV4UsersIdCustomAttributesKey = struct
  module Parameters = struct
    type t = {
      id : int;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/users/{id}/custom_attributes/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("key", Var (params.key, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module PutApiV4UsersIdCustomAttributesKey = struct
  module Parameters = struct
    type t = {
      id : int;
      key : string;
      putapiv4usersidcustomattributeskey : Gitlabc_components.PutApiV4UsersIdCustomAttributesKey.t;
          [@key "putApiV4UsersIdCustomAttributesKey"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/custom_attributes/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("key", Var (params.key, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Put
end

module GetApiV4UsersIdCustomAttributesKey = struct
  module Parameters = struct
    type t = {
      id : int;
      key : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/custom_attributes/{key}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("key", Var (params.key, String)); ("id", Var (params.id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4UsersIdDeactivate = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/deactivate"

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
      `Post
end

module PatchApiV4UsersIdDisableTwoFactor = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/disable_two_factor"

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
      `Patch
end

module PostApiV4UsersIdEmails = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4usersidemails : Gitlabc_components.PostApiV4UsersIdEmails.t;
          [@key "postApiV4UsersIdEmails"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/emails"

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
      `Post
end

module GetApiV4UsersIdEmails = struct
  module Parameters = struct
    type t = {
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/emails"

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
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4UsersIdEmailsEmailId = struct
  module Parameters = struct
    type t = {
      email_id : int;
      id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/emails/{email_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("email_id", Var (params.email_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4UsersIdEvents = struct
  module Parameters = struct
    module Sort = struct
      let t_of_yojson = function
        | `String "asc" -> Ok "asc"
        | `String "desc" -> Ok "desc"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    module Target_type = struct
      let t_of_yojson = function
        | `String "issue" -> Ok "issue"
        | `String "milestone" -> Ok "milestone"
        | `String "merge_request" -> Ok "merge_request"
        | `String "note" -> Ok "note"
        | `String "project" -> Ok "project"
        | `String "snippet" -> Ok "snippet"
        | `String "user" -> Ok "user"
        | `String "wiki" -> Ok "wiki"
        | `String "design" -> Ok "design"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      action : string option; [@default None]
      after : string option; [@default None]
      before : string option; [@default None]
      id : string;
      page : int; [@default 1]
      per_page : int; [@default 20]
      sort : Sort.t; [@default "desc"]
      target_type : Target_type.t option; [@default None]
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

  let url = "/api/v4/users/{id}/events"

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
           ("action", Var (params.action, Option String));
           ("target_type", Var (params.target_type, Option String));
           ("before", Var (params.before, Option String));
           ("after", Var (params.after, Option String));
           ("sort", Var (params.sort, String));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4UsersIdFollow = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/follow"

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
      `Post
end

module GetApiV4UsersIdFollowers = struct
  module Parameters = struct
    type t = {
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/followers"

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
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4UsersIdFollowing = struct
  module Parameters = struct
    type t = {
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/following"

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
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4UsersIdGpgKeys = struct
  module Parameters = struct
    type t = {
      id : int;
      postapiv4usersidgpgkeys : Gitlabc_components.PostApiV4UsersIdGpgKeys.t;
          [@key "postApiV4UsersIdGpgKeys"]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/gpg_keys"

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
      `Post
end

module GetApiV4UsersIdGpgKeys = struct
  module Parameters = struct
    type t = {
      id : int;
      page : int; [@default 1]
      per_page : int; [@default 20]
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/gpg_keys"

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
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module DeleteApiV4UsersIdGpgKeysKeyId = struct
  module Parameters = struct
    type t = {
      id : int;
      key_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/users/{id}/gpg_keys/{key_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("key_id", Var (params.key_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4UsersIdGpgKeysKeyId = struct
  module Parameters = struct
    type t = {
      id : int;
      key_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/gpg_keys/{key_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("key_id", Var (params.key_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4UsersIdGpgKeysKeyIdRevoke = struct
  module Parameters = struct
    type t = {
      id : int;
      key_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/gpg_keys/{key_id}/revoke"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("key_id", Var (params.key_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module DeleteApiV4UsersIdIdentitiesProvider = struct
  module Parameters = struct
    type t = {
      id : int;
      provider : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/identities/{provider}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("provider", Var (params.provider, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module DeleteApiV4UsersIdKeysKeyId = struct
  module Parameters = struct
    type t = {
      id : int;
      key_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/keys/{key_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("key_id", Var (params.key_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4UsersIdKeysKeyId = struct
  module Parameters = struct
    type t = {
      id : int;
      key_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/keys/{key_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("id", Var (params.id, Int)); ("key_id", Var (params.key_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4UsersIdReject = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/reject"

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
      `Post
end

module GetApiV4UsersIdSupportPin = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{id}/support_pin"

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

module PostApiV4UsersIdUnban = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/unban"

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
      `Post
end

module PostApiV4UsersIdUnblock = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/unblock"

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
      `Post
end

module PostApiV4UsersIdUnfollow = struct
  module Parameters = struct
    type t = { id : int } [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{id}/unfollow"

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
      `Post
end

module GetApiV4UsersUserIdContributedProjects = struct
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

    type t = {
      order_by : Order_by.t; [@default "created_at"]
      page : int; [@default 1]
      per_page : int; [@default 20]
      simple : bool; [@default false]
      sort : Sort.t; [@default "desc"]
      user_id : string;
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

  let url = "/api/v4/users/{user_id}/contributed_projects"

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
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
           ("simple", Var (params.simple, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4UsersUserIdImpersonationTokens = struct
  module Parameters = struct
    type t = {
      postapiv4usersuseridimpersonationtokens :
        Gitlabc_components.PostApiV4UsersUserIdImpersonationTokens.t;
          [@key "postApiV4UsersUserIdImpersonationTokens"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{user_id}/impersonation_tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4UsersUserIdImpersonationTokens = struct
  module Parameters = struct
    module State = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "active" -> Ok "active"
        | `String "inactive" -> Ok "inactive"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      page : int; [@default 1]
      per_page : int; [@default 20]
      state : State.t; [@default "all"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{user_id}/impersonation_tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, Int)) ])
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

module DeleteApiV4UsersUserIdImpersonationTokensImpersonationTokenId = struct
  module Parameters = struct
    type t = {
      impersonation_token_id : int;
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module No_content = struct end

    type t = [ `No_content ] [@@deriving show, eq]

    let t = [ ("204", fun _ -> Ok `No_content) ]
  end

  let url = "/api/v4/users/{user_id}/impersonation_tokens/{impersonation_token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("user_id", Var (params.user_id, Int));
           ("impersonation_token_id", Var (params.impersonation_token_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Delete
end

module GetApiV4UsersUserIdImpersonationTokensImpersonationTokenId = struct
  module Parameters = struct
    type t = {
      impersonation_token_id : int;
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{user_id}/impersonation_tokens/{impersonation_token_id}"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("user_id", Var (params.user_id, Int));
           ("impersonation_token_id", Var (params.impersonation_token_id, Int));
         ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4UsersUserIdKeys = struct
  module Parameters = struct
    type t = {
      postapiv4usersuseridkeys : Gitlabc_components.PostApiV4UsersUserIdKeys.t;
          [@key "postApiV4UsersUserIdKeys"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{user_id}/keys"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4UsersUserIdKeys = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 20]
      user_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{user_id}/keys"

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
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4UsersUserIdMemberships = struct
  module Parameters = struct
    module Type = struct
      let t_of_yojson = function
        | `String "Project" -> Ok "Project"
        | `String "Namespace" -> Ok "Namespace"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson]) [@@deriving show, eq]
    end

    type t = {
      page : int; [@default 1]
      per_page : int; [@default 20]
      type_ : Type.t option; [@default None] [@key "type"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{user_id}/memberships"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, Int)) ])
      ~query_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [
           ("type", Var (params.type_, Option String));
           ("page", Var (params.page, Int));
           ("per_page", Var (params.per_page, Int));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

module PostApiV4UsersUserIdPersonalAccessTokens = struct
  module Parameters = struct
    type t = {
      postapiv4usersuseridpersonalaccesstokens :
        Gitlabc_components.PostApiV4UsersUserIdPersonalAccessTokens.t;
          [@key "postApiV4UsersUserIdPersonalAccessTokens"]
      user_id : int;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module Created = struct end

    type t = [ `Created ] [@@deriving show, eq]

    let t = [ ("201", fun _ -> Ok `Created) ]
  end

  let url = "/api/v4/users/{user_id}/personal_access_tokens"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, Int)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Post
end

module GetApiV4UsersUserIdProjectDeployKeys = struct
  module Parameters = struct
    type t = {
      page : int; [@default 1]
      per_page : int; [@default 20]
      user_id : string;
    }
    [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{user_id}/project_deploy_keys"

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
         [ ("page", Var (params.page, Int)); ("per_page", Var (params.per_page, Int)) ])
      ~url
      ~responses:Responses.t
      `Get
end

module GetApiV4UsersUserIdProjects = struct
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
      with_custom_attributes : bool; [@default false]
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

  let url = "/api/v4/users/{user_id}/projects"

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
           ("with_custom_attributes", Var (params.with_custom_attributes, Bool));
         ])
      ~url
      ~responses:Responses.t
      `Get
end

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

module GetApiV4UsersUserIdStatus = struct
  module Parameters = struct
    type t = { user_id : string } [@@deriving make, show, eq]
  end

  module Responses = struct
    module OK = struct end

    type t = [ `OK ] [@@deriving show, eq]

    let t = [ ("200", fun _ -> Ok `OK) ]
  end

  let url = "/api/v4/users/{user_id}/status"

  let make params =
    Openapi.Request.make
      ~headers:[]
      ~url_params:
        (let open Openapi.Request.Var in
         let open Parameters in
         [ ("user_id", Var (params.user_id, String)) ])
      ~query_params:[]
      ~url
      ~responses:Responses.t
      `Get
end
