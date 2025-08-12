type t = {
  availability : string option; [@default None]
  clear_status_at : string option; [@default None]
  emoji : string option; [@default None]
  message : string option; [@default None]
  message_html : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
