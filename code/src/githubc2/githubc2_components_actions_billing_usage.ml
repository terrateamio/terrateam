module Primary = struct
  module Minutes_used_breakdown = struct
    module Primary = struct
      type t = {
        macos : int option; [@default None] [@key "MACOS"]
        ubuntu : int option; [@default None] [@key "UBUNTU"]
        windows : int option; [@default None] [@key "WINDOWS"]
        total : int option; [@default None]
        ubuntu_16_core : int option; [@default None]
        ubuntu_32_core : int option; [@default None]
        ubuntu_4_core : int option; [@default None]
        ubuntu_64_core : int option; [@default None]
        ubuntu_8_core : int option; [@default None]
        windows_16_core : int option; [@default None]
        windows_32_core : int option; [@default None]
        windows_4_core : int option; [@default None]
        windows_64_core : int option; [@default None]
        windows_8_core : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    included_minutes : int;
    minutes_used_breakdown : Minutes_used_breakdown.t;
    total_minutes_used : int;
    total_paid_minutes_used : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
