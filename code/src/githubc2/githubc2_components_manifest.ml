module File = struct
  type t = { source_location : string option [@default None] }
  [@@deriving yojson { strict = true; meta = true }, show]
end

module Resolved = struct
  include
    Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Githubc2_components_dependency)
end

type t = {
  file : File.t option; [@default None]
  metadata : Githubc2_components_metadata.t option; [@default None]
  name : string;
  resolved : Resolved.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, show]
