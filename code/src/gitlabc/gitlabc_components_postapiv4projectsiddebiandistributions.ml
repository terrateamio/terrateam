module Architectures = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Components = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  architectures : Architectures.t option; [@default None]
  codename : string;
  components : Components.t option; [@default None]
  description : string option; [@default None]
  label : string option; [@default None]
  origin : string option; [@default None]
  suite : string option; [@default None]
  valid_time_duration_seconds : int option; [@default None]
  version : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
