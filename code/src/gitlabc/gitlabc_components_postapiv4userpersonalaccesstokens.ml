module Primary = struct
  module Scopes = struct
    module Items = struct
      let t_of_yojson = function
        | `String "k8s_proxy" -> Ok "k8s_proxy"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    description : string option; [@default None]
    expires_at : string option; [@default None]
    name : string;
    scopes : Scopes.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
