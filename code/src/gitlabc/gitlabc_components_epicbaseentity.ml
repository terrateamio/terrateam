type t = {
  group_id : string option; [@default None]
  human_readable_end_date : string option; [@default None]
  human_readable_timestamp : string option; [@default None]
  id : string option; [@default None]
  iid : string option; [@default None]
  title : string option; [@default None]
  url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
