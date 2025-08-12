type t = {
  attachment_url : string option; [@default None]
  classname : string option; [@default None]
  execution_time : int option; [@default None]
  file : string option; [@default None]
  name : string option; [@default None]
  recent_failures : string option; [@default None]
  stack_trace : string option; [@default None]
  status : string option; [@default None]
  system_output : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
