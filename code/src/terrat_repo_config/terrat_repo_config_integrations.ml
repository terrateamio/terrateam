module Resourcely = struct
  module Extra_args = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    enabled : bool;
    extra_args : Extra_args.t option; [@default None]
  }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

type t = { resourcely : Resourcely.t option [@default None] }
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
