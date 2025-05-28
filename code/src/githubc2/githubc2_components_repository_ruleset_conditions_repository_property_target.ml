module Primary = struct
  module Repository_property = struct
    module Primary = struct
      module Exclude = struct
        type t = Githubc2_components_repository_ruleset_conditions_repository_property_spec.t list
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Include = struct
        type t = Githubc2_components_repository_ruleset_conditions_repository_property_spec.t list
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        exclude : Exclude.t option; [@default None]
        include_ : Include.t option; [@default None] [@key "include"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = { repository_property : Repository_property.t }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
