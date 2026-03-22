type t = {
  id: string ;
  refresh_token: string }[@@deriving
                           ((yojson { strict = false; meta = true }), show,
                             eq)]
