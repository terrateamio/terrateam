module Primary = struct
  module Checks = struct
    module Items = struct
      module Primary = struct
        type t = {
          app_id : int option;
          context : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Contexts = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    checks : Checks.t;
    contexts : Contexts.t;
    contexts_url : string option; [@default None]
    enforcement_level : string option; [@default None]
    strict : bool option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
