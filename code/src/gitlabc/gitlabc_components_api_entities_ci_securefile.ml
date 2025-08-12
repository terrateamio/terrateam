module Metadata = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = {
  checksum : string option; [@default None]
  checksum_algorithm : string option; [@default None]
  created_at : string option; [@default None]
  expires_at : string option; [@default None]
  file_extension : string option; [@default None]
  id : int option; [@default None]
  metadata : Metadata.t option; [@default None]
  name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
