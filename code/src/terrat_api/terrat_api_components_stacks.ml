module Stacks_ = struct
  type t = Terrat_api_components_stack_outer.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { stacks : Stacks_.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
