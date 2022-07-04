module Output = struct
  module Primary = struct
    module Errors = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = { errors : Errors.t option [@default None] }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Additional)
end

type t = {
  output : Output.t;
  path : string;
  success : bool;
  workspace : string;
}
[@@deriving yojson { strict = true; meta = true }, show]
