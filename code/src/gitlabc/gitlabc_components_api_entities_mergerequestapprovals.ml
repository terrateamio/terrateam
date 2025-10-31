module Approved_by = struct
  type t = Gitlabc_components_api_entities_approvals.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { approved_by : Approved_by.t option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
