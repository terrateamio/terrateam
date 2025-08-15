module Action = struct
  let t_of_yojson = function
    | `String "suspend" -> Ok "suspend"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Installation_ = struct
  module All_of = struct
    module Primary = struct
      module Created_at = struct
        module V0 = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module V1 = struct
          type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t =
          | V0 of V0.t
          | V1 of V1.t
        [@@deriving show, eq]

        let of_yojson =
          Json_schema.one_of
            (let open CCResult in
             [
               (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
               (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
             ])

        let to_yojson = function
          | V0 v -> V0.to_yojson v
          | V1 v -> V1.to_yojson v
      end

      module Events = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Permissions = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      module Single_file_paths = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Target_type = struct
        let t_of_yojson = function
          | `String "User" -> Ok "User"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Updated_at = struct
        module V0 = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module V1 = struct
          type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t =
          | V0 of V0.t
          | V1 of V1.t
        [@@deriving show, eq]

        let of_yojson =
          Json_schema.one_of
            (let open CCResult in
             [
               (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
               (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
             ])

        let to_yojson = function
          | V0 v -> V0.to_yojson v
          | V1 v -> V1.to_yojson v
      end

      type t = {
        access_tokens_url : string;
        account : Terrat_github_webhooks_user.t;
        app_id : int;
        app_slug : string option; [@default None]
        created_at : Created_at.t;
        events : Events.t;
        has_multiple_single_files : bool option; [@default None]
        html_url : string;
        id : int;
        permissions : Permissions.t;
        repositories_url : string;
        repository_selection : string;
        single_file_name : string option; [@default None]
        single_file_paths : Single_file_paths.t option; [@default None]
        suspended_at : string option; [@default None]
        suspended_by : Terrat_github_webhooks_user.t;
        target_id : int;
        target_type : Target_type.t;
        updated_at : Updated_at.t;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Created_at = struct
        module V0 = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module V1 = struct
          type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t =
          | V0 of V0.t
          | V1 of V1.t
        [@@deriving show, eq]

        let of_yojson =
          Json_schema.one_of
            (let open CCResult in
             [
               (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
               (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
             ])

        let to_yojson = function
          | V0 v -> V0.to_yojson v
          | V1 v -> V1.to_yojson v
      end

      module Events = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Permissions = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      module Single_file_paths = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Target_type = struct
        let t_of_yojson = function
          | `String "User" -> Ok "User"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Updated_at = struct
        module V0 = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module V1 = struct
          type t = int [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t =
          | V0 of V0.t
          | V1 of V1.t
        [@@deriving show, eq]

        let of_yojson =
          Json_schema.one_of
            (let open CCResult in
             [
               (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
               (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
             ])

        let to_yojson = function
          | V0 v -> V0.to_yojson v
          | V1 v -> V1.to_yojson v
      end

      type t = {
        access_tokens_url : string;
        account : Terrat_github_webhooks_user.t;
        app_id : int;
        app_slug : string option; [@default None]
        created_at : Created_at.t;
        events : Events.t;
        has_multiple_single_files : bool option; [@default None]
        html_url : string;
        id : int;
        permissions : Permissions.t;
        repositories_url : string;
        repository_selection : string;
        single_file_name : string option; [@default None]
        single_file_paths : Single_file_paths.t option; [@default None]
        suspended_at : string option; [@default None]
        suspended_by : Terrat_github_webhooks_user.t;
        target_id : int;
        target_type : Target_type.t;
        updated_at : Updated_at.t;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module Repositories = struct
  module Items = struct
    type t = {
      full_name : string;
      id : int;
      name : string;
      node_id : string;
      private_ : bool; [@key "private"]
    }
    [@@deriving yojson { strict = false; meta = true }, make, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Requester = struct
  type t = unit [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  action : Action.t;
  installation : Installation_.t;
  repositories : Repositories.t option; [@default None]
  requester : Requester.t option; [@default None]
  sender : Terrat_github_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
