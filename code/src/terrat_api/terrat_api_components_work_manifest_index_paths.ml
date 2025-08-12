module Additional = struct
  module Failures = struct
    module Additional = struct
      type t = {
        lnum : int option; [@default None]
        msg : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
  end

  module Modules = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    failures : Failures.t;
    modules : Modules.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
