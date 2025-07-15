module Kas = struct
  module Primary = struct
    type t = {
      enabled : bool option; [@default None]
      externalk8sproxyurl : string option; [@default None] [@key "externalK8sProxyUrl"]
      externalurl : string option; [@default None] [@key "externalUrl"]
      version : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = {
  enterprise : bool option; [@default None]
  kas : Kas.t option; [@default None]
  revision : string option; [@default None]
  version : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
