module Scopes = struct
  module Items = struct
    let t_of_yojson = function
      | `String "k8s_proxy" -> Ok `K8s_proxy
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `K8s_proxy -> `String "k8s_proxy"

    type t = ([ `K8s_proxy ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
