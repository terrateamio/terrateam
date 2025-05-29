module Primary = struct
  module Fetches = struct
    module Primary = struct
      module Days = struct
        type t = Gitlabc_components_api_entities_projectdailyfetches.t list
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        days : Days.t option; [@default None]
        total : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = { fetches : Fetches.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
