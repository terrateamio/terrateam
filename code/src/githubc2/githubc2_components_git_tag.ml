module Primary = struct
  module Object = struct
    module Primary = struct
      type t = {
        sha : string;
        type_ : string; [@key "type"]
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Tagger = struct
    module Primary = struct
      type t = {
        date : string;
        email : string;
        name : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    message : string;
    node_id : string;
    object_ : Object.t; [@key "object"]
    sha : string;
    tag : string;
    tagger : Tagger.t;
    url : string;
    verification : Githubc2_components_verification.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
