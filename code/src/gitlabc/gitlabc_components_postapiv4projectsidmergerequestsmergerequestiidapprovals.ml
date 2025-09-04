type t = { approvals_required : int } [@@deriving yojson { strict = false; meta = true }, show, eq]
