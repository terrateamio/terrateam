type t = {
  agent_id : string option; [@default None]
  created_at : string option; [@default None]
  created_by_user_id : string option; [@default None]
  description : string option; [@default None]
  id : string option; [@default None]
  last_used_at : string option; [@default None]
  name : string option; [@default None]
  status : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
