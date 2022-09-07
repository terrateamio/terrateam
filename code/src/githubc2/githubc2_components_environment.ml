module Primary = struct
  module Protection_rules = struct
    module Items = struct
      module V0 = struct
        module Primary = struct
          type t = {
            id : int;
            node_id : string;
            type_ : string; [@key "type"]
            wait_timer : int option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module V1 = struct
        module Primary = struct
          module Reviewers = struct
            module Items = struct
              module Primary = struct
                module Reviewer = struct
                  type t =
                    | Simple_user of Githubc2_components_simple_user.t
                    | Team of Githubc2_components_team.t
                  [@@deriving show]

                  let of_yojson =
                    Json_schema.any_of
                      (let open CCResult in
                      [
                        (fun v ->
                          map (fun v -> Simple_user v) (Githubc2_components_simple_user.of_yojson v));
                        (fun v -> map (fun v -> Team v) (Githubc2_components_team.of_yojson v));
                      ])

                  let to_yojson = function
                    | Simple_user v -> Githubc2_components_simple_user.to_yojson v
                    | Team v -> Githubc2_components_team.to_yojson v
                end

                type t = {
                  reviewer : Reviewer.t option; [@default None]
                  type_ : Githubc2_components_deployment_reviewer_type.t option;
                      [@default None] [@key "type"]
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = {
            id : int;
            node_id : string;
            reviewers : Reviewers.t option; [@default None]
            type_ : string; [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module V2 = struct
        module Primary = struct
          type t = {
            id : int;
            node_id : string;
            type_ : string; [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t =
        | V0 of V0.t
        | V1 of V1.t
        | V2 of V2.t
      [@@deriving show]

      let of_yojson =
        Json_schema.any_of
          (let open CCResult in
          [
            (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
            (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
            (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
          ])

      let to_yojson = function
        | V0 v -> V0.to_yojson v
        | V1 v -> V1.to_yojson v
        | V2 v -> V2.to_yojson v
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    created_at : string;
    deployment_branch_policy : Githubc2_components_deployment_branch_policy_settings.t option;
        [@default None]
    html_url : string;
    id : int;
    name : string;
    node_id : string;
    protection_rules : Protection_rules.t option; [@default None]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
