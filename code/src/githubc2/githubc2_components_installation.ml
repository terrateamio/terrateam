module Primary = struct
  module Account = struct
    type t =
      | Simple_user of Githubc2_components_simple_user.t
      | Enterprise of Githubc2_components_enterprise.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.any_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> Simple_user v) (Githubc2_components_simple_user.of_yojson v));
           (fun v -> map (fun v -> Enterprise v) (Githubc2_components_enterprise.of_yojson v));
         ])

    let to_yojson = function
      | Simple_user v -> Githubc2_components_simple_user.to_yojson v
      | Enterprise v -> Githubc2_components_enterprise.to_yojson v
  end

  module Events = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Repository_selection = struct
    let t_of_yojson = function
      | `String "all" -> Ok "all"
      | `String "selected" -> Ok "selected"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Single_file_paths = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    access_tokens_url : string;
    account : Account.t option; [@default None]
    app_id : int;
    app_slug : string;
    contact_email : string option; [@default None]
    created_at : string;
    events : Events.t;
    has_multiple_single_files : bool option; [@default None]
    html_url : string;
    id : int;
    permissions : Githubc2_components_app_permissions.t;
    repositories_url : string;
    repository_selection : Repository_selection.t;
    single_file_name : string option; [@default None]
    single_file_paths : Single_file_paths.t option; [@default None]
    suspended_at : string option; [@default None]
    suspended_by : Githubc2_components_nullable_simple_user.t option; [@default None]
    target_id : int;
    target_type : string;
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
