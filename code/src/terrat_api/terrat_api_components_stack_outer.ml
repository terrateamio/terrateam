module Stacks_ = struct
  type t = Terrat_api_components_stack_inner.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  name : string;
  stacks : Stacks_.t;
  state : Terrat_api_components_stack_state.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
