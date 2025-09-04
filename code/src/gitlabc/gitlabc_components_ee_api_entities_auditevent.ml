type t = {
  author_id : string option; [@default None]
  created_at : string option; [@default None]
  details : string option; [@default None]
  entity_id : string option; [@default None]
  entity_type : string option; [@default None]
  event_name : string option; [@default None]
  id : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
