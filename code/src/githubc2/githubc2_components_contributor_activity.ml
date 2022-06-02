module Primary = struct
  module Weeks = struct
    module Items = struct
      module Primary = struct
        type t = {
          a : int option; [@default None]
          c : int option; [@default None]
          d : int option; [@default None]
          w : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    author : Githubc2_components_nullable_simple_user.t option;
    total : int;
    weeks : Weeks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
