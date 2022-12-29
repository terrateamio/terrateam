module Primary = struct
  module Preferences = struct
    module Primary = struct
      module Auto_trigger_checks = struct
        module Items = struct
          module Primary = struct
            type t = {
              app_id : int;
              setting : bool;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { auto_trigger_checks : Auto_trigger_checks.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    preferences : Preferences.t;
    repository : Githubc2_components_minimal_repository.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
