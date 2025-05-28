module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "edited" -> Ok "edited"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Changes = struct
    module V0 = struct
      module Primary = struct
        module Field_value = struct
          module Primary = struct
            module From = struct
              module V0 = struct
                type t = string option [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module V1 = struct
                type t = int option [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t =
                | V0 of V0.t
                | V1 of V1.t
                | V2 of Githubc2_components_projects_v2_single_select_option.t
                | V3 of Githubc2_components_projects_v2_iteration_setting.t
              [@@deriving show, eq]

              let of_yojson =
                Json_schema.one_of
                  (let open CCResult in
                   [
                     (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                     (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                     (fun v ->
                       map
                         (fun v -> V2 v)
                         (Githubc2_components_projects_v2_single_select_option.of_yojson v));
                     (fun v ->
                       map
                         (fun v -> V3 v)
                         (Githubc2_components_projects_v2_iteration_setting.of_yojson v));
                   ])

              let to_yojson = function
                | V0 v -> V0.to_yojson v
                | V1 v -> V1.to_yojson v
                | V2 v -> Githubc2_components_projects_v2_single_select_option.to_yojson v
                | V3 v -> Githubc2_components_projects_v2_iteration_setting.to_yojson v
            end

            module To = struct
              module V0 = struct
                type t = string option [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              module V1 = struct
                type t = int option [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t =
                | V0 of V0.t
                | V1 of V1.t
                | V2 of Githubc2_components_projects_v2_single_select_option.t
                | V3 of Githubc2_components_projects_v2_iteration_setting.t
              [@@deriving show, eq]

              let of_yojson =
                Json_schema.one_of
                  (let open CCResult in
                   [
                     (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                     (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                     (fun v ->
                       map
                         (fun v -> V2 v)
                         (Githubc2_components_projects_v2_single_select_option.of_yojson v));
                     (fun v ->
                       map
                         (fun v -> V3 v)
                         (Githubc2_components_projects_v2_iteration_setting.of_yojson v));
                   ])

              let to_yojson = function
                | V0 v -> V0.to_yojson v
                | V1 v -> V1.to_yojson v
                | V2 v -> Githubc2_components_projects_v2_single_select_option.to_yojson v
                | V3 v -> Githubc2_components_projects_v2_iteration_setting.to_yojson v
            end

            type t = {
              field_name : string option; [@default None]
              field_node_id : string option; [@default None]
              field_type : string option; [@default None]
              from : From.t option; [@default None]
              project_number : int option; [@default None]
              to_ : To.t option; [@default None] [@key "to"]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = { field_value : Field_value.t }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module V1 = struct
      module Primary = struct
        module Body = struct
          module Primary = struct
            type t = {
              from : string option; [@default None]
              to_ : string option; [@default None] [@key "to"]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = { body : Body.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
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
    action : Action.t;
    changes : Changes.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t;
    projects_v2_item : Githubc2_components_projects_v2_item.t;
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
