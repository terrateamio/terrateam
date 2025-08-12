type t = { approvals_required : int option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]
