module Primary = struct
  module Billable = struct
    module Primary = struct
      module MACOS = struct
        module Primary = struct
          type t = { total_ms : int option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module UBUNTU = struct
        module Primary = struct
          type t = { total_ms : int option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module WINDOWS = struct
        module Primary = struct
          type t = { total_ms : int option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        macos : MACOS.t option; [@default None] [@key "MACOS"]
        ubuntu : UBUNTU.t option; [@default None] [@key "UBUNTU"]
        windows : WINDOWS.t option; [@default None] [@key "WINDOWS"]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = { billable : Billable.t } [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
