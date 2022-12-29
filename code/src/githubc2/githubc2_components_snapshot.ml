module Detector = struct
  type t = {
    name : string;
    url : string;
    version : string;
  }
  [@@deriving yojson { strict = true; meta = true }, show, eq]
end

module Job_ = struct
  type t = {
    correlator : string;
    html_url : string option; [@default None]
    id : string;
  }
  [@@deriving yojson { strict = true; meta = true }, show, eq]
end

module Manifests = struct
  include
    Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Githubc2_components_manifest)
end

type t = {
  detector : Detector.t;
  job : Job_.t;
  manifests : Manifests.t option; [@default None]
  metadata : Githubc2_components_metadata.t option; [@default None]
  ref_ : string; [@key "ref"]
  scanned : string;
  sha : string;
  version : int;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
