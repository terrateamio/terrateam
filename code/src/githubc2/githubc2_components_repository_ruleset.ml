module Primary = struct
  module Links_ = struct
    module Primary = struct
      module Html = struct
        module Primary = struct
          type t = { href : string option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Self = struct
        module Primary = struct
          type t = { href : string option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        html : Html.t option; [@default None]
        self : Self.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Bypass_actors = struct
    type t = Githubc2_components_repository_ruleset_bypass_actor.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Conditions = struct
    type t =
      | Repository_ruleset_conditions of Githubc2_components_repository_ruleset_conditions.t
      | Org_ruleset_conditions of Githubc2_components_org_ruleset_conditions.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.any_of
        (let open CCResult in
         [
           (fun v ->
             map
               (fun v -> Repository_ruleset_conditions v)
               (Githubc2_components_repository_ruleset_conditions.of_yojson v));
           (fun v ->
             map
               (fun v -> Org_ruleset_conditions v)
               (Githubc2_components_org_ruleset_conditions.of_yojson v));
         ])

    let to_yojson = function
      | Repository_ruleset_conditions v ->
          Githubc2_components_repository_ruleset_conditions.to_yojson v
      | Org_ruleset_conditions v -> Githubc2_components_org_ruleset_conditions.to_yojson v
  end

  module Current_user_can_bypass = struct
    let t_of_yojson = function
      | `String "always" -> Ok "always"
      | `String "pull_requests_only" -> Ok "pull_requests_only"
      | `String "never" -> Ok "never"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Rules = struct
    type t = Githubc2_components_repository_rule.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Source_type = struct
    let t_of_yojson = function
      | `String "Repository" -> Ok "Repository"
      | `String "Organization" -> Ok "Organization"
      | `String "Enterprise" -> Ok "Enterprise"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Target = struct
    let t_of_yojson = function
      | `String "branch" -> Ok "branch"
      | `String "tag" -> Ok "tag"
      | `String "push" -> Ok "push"
      | `String "repository" -> Ok "repository"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    links_ : Links_.t option; [@default None] [@key "_links"]
    bypass_actors : Bypass_actors.t option; [@default None]
    conditions : Conditions.t option; [@default None]
    created_at : string option; [@default None]
    current_user_can_bypass : Current_user_can_bypass.t option; [@default None]
    enforcement : Githubc2_components_repository_rule_enforcement.t;
    id : int;
    name : string;
    node_id : string option; [@default None]
    rules : Rules.t option; [@default None]
    source : string;
    source_type : Source_type.t option; [@default None]
    target : Target.t option; [@default None]
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
