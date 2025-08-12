module Scopes = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  description : string option; [@default None]
  expires_at : string option; [@default None]
  name : string;
  scopes : Scopes.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
