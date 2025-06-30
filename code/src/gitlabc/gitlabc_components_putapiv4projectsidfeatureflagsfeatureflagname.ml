module Primary = struct
  module Strategies = struct
    module Items = struct
      module Primary = struct
        module Scopes = struct
          module Items = struct
            module Primary = struct
              type t = {
                destroy_ : bool option; [@default None] [@key "_destroy"]
                environment_scope : string option; [@default None]
                id : int option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = {
          destroy_ : bool option; [@default None] [@key "_destroy"]
          id : int option; [@default None]
          name : string option; [@default None]
          parameters : string option; [@default None]
          scopes : Scopes.t option; [@default None]
          user_list_id : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    active : bool option; [@default None]
    description : string option; [@default None]
    name : string option; [@default None]
    strategies : Strategies.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
