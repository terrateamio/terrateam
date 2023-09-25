module V0 = struct
  module All_of = struct
    module Primary = struct
      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "creation" -> Ok "creation"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "creation" -> Ok "creation"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V1 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          type t = { update_allows_fetch_and_merge : bool }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "update" -> Ok "update"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          type t = { update_allows_fetch_and_merge : bool }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "update" -> Ok "update"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V2 = struct
  module All_of = struct
    module Primary = struct
      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "deletion" -> Ok "deletion"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "deletion" -> Ok "deletion"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V3 = struct
  module All_of = struct
    module Primary = struct
      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "required_linear_history" -> Ok "required_linear_history"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "required_linear_history" -> Ok "required_linear_history"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V4 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Required_deployment_environments = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { required_deployment_environments : Required_deployment_environments.t }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "required_deployments" -> Ok "required_deployments"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Required_deployment_environments = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { required_deployment_environments : Required_deployment_environments.t }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "required_deployments" -> Ok "required_deployments"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V5 = struct
  module All_of = struct
    module Primary = struct
      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "required_signatures" -> Ok "required_signatures"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "required_signatures" -> Ok "required_signatures"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V6 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          type t = {
            dismiss_stale_reviews_on_push : bool;
            require_code_owner_review : bool;
            require_last_push_approval : bool;
            required_approving_review_count : int;
            required_review_thread_resolution : bool;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "pull_request" -> Ok "pull_request"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          type t = {
            dismiss_stale_reviews_on_push : bool;
            require_code_owner_review : bool;
            require_last_push_approval : bool;
            required_approving_review_count : int;
            required_review_thread_resolution : bool;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "pull_request" -> Ok "pull_request"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V7 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Required_status_checks = struct
            type t = Githubc2_components_repository_rule_params_status_check_configuration.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            required_status_checks : Required_status_checks.t;
            strict_required_status_checks_policy : bool;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "required_status_checks" -> Ok "required_status_checks"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Required_status_checks = struct
            type t = Githubc2_components_repository_rule_params_status_check_configuration.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            required_status_checks : Required_status_checks.t;
            strict_required_status_checks_policy : bool;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "required_status_checks" -> Ok "required_status_checks"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V8 = struct
  module All_of = struct
    module Primary = struct
      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "non_fast_forward" -> Ok "non_fast_forward"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "non_fast_forward" -> Ok "non_fast_forward"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V9 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Operator = struct
            let t_of_yojson = function
              | `String "starts_with" -> Ok "starts_with"
              | `String "ends_with" -> Ok "ends_with"
              | `String "contains" -> Ok "contains"
              | `String "regex" -> Ok "regex"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            name : string option; [@default None]
            negate : bool option; [@default None]
            operator : Operator.t;
            pattern : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "commit_message_pattern" -> Ok "commit_message_pattern"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Operator = struct
            let t_of_yojson = function
              | `String "starts_with" -> Ok "starts_with"
              | `String "ends_with" -> Ok "ends_with"
              | `String "contains" -> Ok "contains"
              | `String "regex" -> Ok "regex"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            name : string option; [@default None]
            negate : bool option; [@default None]
            operator : Operator.t;
            pattern : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "commit_message_pattern" -> Ok "commit_message_pattern"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V10 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Operator = struct
            let t_of_yojson = function
              | `String "starts_with" -> Ok "starts_with"
              | `String "ends_with" -> Ok "ends_with"
              | `String "contains" -> Ok "contains"
              | `String "regex" -> Ok "regex"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            name : string option; [@default None]
            negate : bool option; [@default None]
            operator : Operator.t;
            pattern : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "commit_author_email_pattern" -> Ok "commit_author_email_pattern"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Operator = struct
            let t_of_yojson = function
              | `String "starts_with" -> Ok "starts_with"
              | `String "ends_with" -> Ok "ends_with"
              | `String "contains" -> Ok "contains"
              | `String "regex" -> Ok "regex"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            name : string option; [@default None]
            negate : bool option; [@default None]
            operator : Operator.t;
            pattern : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "commit_author_email_pattern" -> Ok "commit_author_email_pattern"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V11 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Operator = struct
            let t_of_yojson = function
              | `String "starts_with" -> Ok "starts_with"
              | `String "ends_with" -> Ok "ends_with"
              | `String "contains" -> Ok "contains"
              | `String "regex" -> Ok "regex"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            name : string option; [@default None]
            negate : bool option; [@default None]
            operator : Operator.t;
            pattern : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "committer_email_pattern" -> Ok "committer_email_pattern"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Operator = struct
            let t_of_yojson = function
              | `String "starts_with" -> Ok "starts_with"
              | `String "ends_with" -> Ok "ends_with"
              | `String "contains" -> Ok "contains"
              | `String "regex" -> Ok "regex"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            name : string option; [@default None]
            negate : bool option; [@default None]
            operator : Operator.t;
            pattern : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "committer_email_pattern" -> Ok "committer_email_pattern"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V12 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Operator = struct
            let t_of_yojson = function
              | `String "starts_with" -> Ok "starts_with"
              | `String "ends_with" -> Ok "ends_with"
              | `String "contains" -> Ok "contains"
              | `String "regex" -> Ok "regex"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            name : string option; [@default None]
            negate : bool option; [@default None]
            operator : Operator.t;
            pattern : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "branch_name_pattern" -> Ok "branch_name_pattern"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Operator = struct
            let t_of_yojson = function
              | `String "starts_with" -> Ok "starts_with"
              | `String "ends_with" -> Ok "ends_with"
              | `String "contains" -> Ok "contains"
              | `String "regex" -> Ok "regex"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            name : string option; [@default None]
            negate : bool option; [@default None]
            operator : Operator.t;
            pattern : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "branch_name_pattern" -> Ok "branch_name_pattern"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

module V13 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Operator = struct
            let t_of_yojson = function
              | `String "starts_with" -> Ok "starts_with"
              | `String "ends_with" -> Ok "ends_with"
              | `String "contains" -> Ok "contains"
              | `String "regex" -> Ok "regex"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            name : string option; [@default None]
            negate : bool option; [@default None]
            operator : Operator.t;
            pattern : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "tag_name_pattern" -> Ok "tag_name_pattern"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module T = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Operator = struct
            let t_of_yojson = function
              | `String "starts_with" -> Ok "starts_with"
              | `String "ends_with" -> Ok "ends_with"
              | `String "contains" -> Ok "contains"
              | `String "regex" -> Ok "regex"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            name : string option; [@default None]
            negate : bool option; [@default None]
            operator : Operator.t;
            pattern : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Ruleset_source_type = struct
        let t_of_yojson = function
          | `String "Repository" -> Ok "Repository"
          | `String "Organization" -> Ok "Organization"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Type = struct
        let t_of_yojson = function
          | `String "tag_name_pattern" -> Ok "tag_name_pattern"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        parameters : Parameters.t option; [@default None]
        ruleset_id : int option; [@default None]
        ruleset_source : string option; [@default None]
        ruleset_source_type : Ruleset_source_type.t option; [@default None]
        type_ : Type.t; [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

  let of_yojson json =
    let open CCResult in
    flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
end

type t =
  | V0 of V0.t
  | V1 of V1.t
  | V2 of V2.t
  | V3 of V3.t
  | V4 of V4.t
  | V5 of V5.t
  | V6 of V6.t
  | V7 of V7.t
  | V8 of V8.t
  | V9 of V9.t
  | V10 of V10.t
  | V11 of V11.t
  | V12 of V12.t
  | V13 of V13.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
       (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
       (fun v -> map (fun v -> V3 v) (V3.of_yojson v));
       (fun v -> map (fun v -> V4 v) (V4.of_yojson v));
       (fun v -> map (fun v -> V5 v) (V5.of_yojson v));
       (fun v -> map (fun v -> V6 v) (V6.of_yojson v));
       (fun v -> map (fun v -> V7 v) (V7.of_yojson v));
       (fun v -> map (fun v -> V8 v) (V8.of_yojson v));
       (fun v -> map (fun v -> V9 v) (V9.of_yojson v));
       (fun v -> map (fun v -> V10 v) (V10.of_yojson v));
       (fun v -> map (fun v -> V11 v) (V11.of_yojson v));
       (fun v -> map (fun v -> V12 v) (V12.of_yojson v));
       (fun v -> map (fun v -> V13 v) (V13.of_yojson v));
     ])

let to_yojson = function
  | V0 v -> V0.to_yojson v
  | V1 v -> V1.to_yojson v
  | V2 v -> V2.to_yojson v
  | V3 v -> V3.to_yojson v
  | V4 v -> V4.to_yojson v
  | V5 v -> V5.to_yojson v
  | V6 v -> V6.to_yojson v
  | V7 v -> V7.to_yojson v
  | V8 v -> V8.to_yojson v
  | V9 v -> V9.to_yojson v
  | V10 v -> V10.to_yojson v
  | V11 v -> V11.to_yojson v
  | V12 v -> V12.to_yojson v
  | V13 v -> V13.to_yojson v
