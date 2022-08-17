module Primary = struct
  module Errors = struct
    module Items = struct
      module Primary = struct
        type t = {
          column : int;
          kind : string;
          line : int;
          message : string;
          path : string;
          source : string option; [@default None]
          suggestion : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = { errors : Errors.t } [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
