module Primary = struct
  module Cvss_v3 = struct
    module Primary = struct
      type t = {
        score : float option;
        vector_string : string option;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Cvss_v4 = struct
    module Primary = struct
      type t = {
        score : float option;
        vector_string : string option;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    cvss_v3 : Cvss_v3.t option; [@default None]
    cvss_v4 : Cvss_v4.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
