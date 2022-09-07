module Primary = struct
  module Environment_ = struct
    module Primary = struct
      type t = {
        html_url : string option; [@default None]
        id : int option; [@default None]
        name : string option; [@default None]
        node_id : string option; [@default None]
        url : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

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
    current_user_can_approve : bool;
    environment : Environment_.t;
    reviewers : Reviewers.t;
    wait_timer : int;
    wait_timer_started_at : string option;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
