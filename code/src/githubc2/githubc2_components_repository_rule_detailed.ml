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
          module Grouping_strategy = struct
            let t_of_yojson = function
              | `String "ALLGREEN" -> Ok "ALLGREEN"
              | `String "HEADGREEN" -> Ok "HEADGREEN"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Merge_method = struct
            let t_of_yojson = function
              | `String "MERGE" -> Ok "MERGE"
              | `String "SQUASH" -> Ok "SQUASH"
              | `String "REBASE" -> Ok "REBASE"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            check_response_timeout_minutes : int;
            grouping_strategy : Grouping_strategy.t;
            max_entries_to_build : int;
            max_entries_to_merge : int;
            merge_method : Merge_method.t;
            min_entries_to_merge : int;
            min_entries_to_merge_wait_minutes : int;
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
          | `String "merge_queue" -> Ok "merge_queue"
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
          module Grouping_strategy = struct
            let t_of_yojson = function
              | `String "ALLGREEN" -> Ok "ALLGREEN"
              | `String "HEADGREEN" -> Ok "HEADGREEN"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Merge_method = struct
            let t_of_yojson = function
              | `String "MERGE" -> Ok "MERGE"
              | `String "SQUASH" -> Ok "SQUASH"
              | `String "REBASE" -> Ok "REBASE"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            check_response_timeout_minutes : int;
            grouping_strategy : Grouping_strategy.t;
            max_entries_to_build : int;
            max_entries_to_merge : int;
            merge_method : Merge_method.t;
            min_entries_to_merge : int;
            min_entries_to_merge_wait_minutes : int;
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
          | `String "merge_queue" -> Ok "merge_queue"
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

module V6 = struct
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

module V7 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Allowed_merge_methods = struct
            module Items = struct
              let t_of_yojson = function
                | `String "merge" -> Ok "merge"
                | `String "squash" -> Ok "squash"
                | `String "rebase" -> Ok "rebase"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            allowed_merge_methods : Allowed_merge_methods.t option; [@default None]
            automatic_copilot_code_review_enabled : bool option; [@default None]
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
          module Allowed_merge_methods = struct
            module Items = struct
              let t_of_yojson = function
                | `String "merge" -> Ok "merge"
                | `String "squash" -> Ok "squash"
                | `String "rebase" -> Ok "rebase"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            allowed_merge_methods : Allowed_merge_methods.t option; [@default None]
            automatic_copilot_code_review_enabled : bool option; [@default None]
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

module V8 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Required_status_checks = struct
            type t = Githubc2_components_repository_rule_params_status_check_configuration.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            do_not_enforce_on_create : bool option; [@default None]
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
            do_not_enforce_on_create : bool option; [@default None]
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

module V9 = struct
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

module V14 = struct
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

module V15 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Restricted_file_paths = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { restricted_file_paths : Restricted_file_paths.t }
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
          | `String "file_path_restriction" -> Ok "file_path_restriction"
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
          module Restricted_file_paths = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { restricted_file_paths : Restricted_file_paths.t }
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
          | `String "file_path_restriction" -> Ok "file_path_restriction"
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

module V16 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          type t = { max_file_path_length : int }
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
          | `String "max_file_path_length" -> Ok "max_file_path_length"
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
          type t = { max_file_path_length : int }
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
          | `String "max_file_path_length" -> Ok "max_file_path_length"
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

module V17 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Restricted_file_extensions = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { restricted_file_extensions : Restricted_file_extensions.t }
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
          | `String "file_extension_restriction" -> Ok "file_extension_restriction"
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
          module Restricted_file_extensions = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { restricted_file_extensions : Restricted_file_extensions.t }
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
          | `String "file_extension_restriction" -> Ok "file_extension_restriction"
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

module V18 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          type t = { max_file_size : int }
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
          | `String "max_file_size" -> Ok "max_file_size"
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
          type t = { max_file_size : int }
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
          | `String "max_file_size" -> Ok "max_file_size"
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

module V19 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Workflows = struct
            type t = Githubc2_components_repository_rule_params_workflow_file_reference.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            do_not_enforce_on_create : bool option; [@default None]
            workflows : Workflows.t;
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
          | `String "workflows" -> Ok "workflows"
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
          module Workflows = struct
            type t = Githubc2_components_repository_rule_params_workflow_file_reference.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            do_not_enforce_on_create : bool option; [@default None]
            workflows : Workflows.t;
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
          | `String "workflows" -> Ok "workflows"
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

module V20 = struct
  module All_of = struct
    module Primary = struct
      module Parameters = struct
        module Primary = struct
          module Code_scanning_tools = struct
            type t = Githubc2_components_repository_rule_params_code_scanning_tool.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { code_scanning_tools : Code_scanning_tools.t }
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
          | `String "code_scanning" -> Ok "code_scanning"
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
          module Code_scanning_tools = struct
            type t = Githubc2_components_repository_rule_params_code_scanning_tool.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { code_scanning_tools : Code_scanning_tools.t }
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
          | `String "code_scanning" -> Ok "code_scanning"
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
  | V14 of V14.t
  | V15 of V15.t
  | V16 of V16.t
  | V17 of V17.t
  | V18 of V18.t
  | V19 of V19.t
  | V20 of V20.t
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
       (fun v -> map (fun v -> V14 v) (V14.of_yojson v));
       (fun v -> map (fun v -> V15 v) (V15.of_yojson v));
       (fun v -> map (fun v -> V16 v) (V16.of_yojson v));
       (fun v -> map (fun v -> V17 v) (V17.of_yojson v));
       (fun v -> map (fun v -> V18 v) (V18.of_yojson v));
       (fun v -> map (fun v -> V19 v) (V19.of_yojson v));
       (fun v -> map (fun v -> V20 v) (V20.of_yojson v));
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
  | V14 v -> V14.to_yojson v
  | V15 v -> V15.to_yojson v
  | V16 v -> V16.to_yojson v
  | V17 v -> V17.to_yojson v
  | V18 v -> V18.to_yojson v
  | V19 v -> V19.to_yojson v
  | V20 v -> V20.to_yojson v
