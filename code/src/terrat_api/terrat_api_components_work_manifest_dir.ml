module Variables = struct
  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

type t = {
  path : string;
  rank : int;
  stack_name : string;
  variables : Variables.t option; [@default None]
  workflow : int option; [@default None]
  workspace : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
