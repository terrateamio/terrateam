module Milestones = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  description : string option; [@default None]
  milestone_ids : string option; [@default None]
  milestones : Milestones.t option; [@default None]
  name : string option; [@default None]
  released_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
