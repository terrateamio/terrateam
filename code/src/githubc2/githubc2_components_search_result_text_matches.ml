module Items = struct
  module Primary = struct
    module Matches = struct
      module Items = struct
        module Primary = struct
          module Indices = struct
            type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            indices : Indices.t option; [@default None]
            text : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      fragment : string option; [@default None]
      matches : Matches.t option; [@default None]
      object_type : string option; [@default None]
      object_url : string option; [@default None]
      property : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
