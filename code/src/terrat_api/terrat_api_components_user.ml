module Vcs = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  id : string;
  vcs : Vcs.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
