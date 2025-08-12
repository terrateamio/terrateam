type t = {
  column_name : string option; [@default None]
  created_at : string option; [@default None]
  id : string option; [@default None]
  job_class_name : string option; [@default None]
  progress : float option; [@default None]
  status : string option; [@default None]
  table_name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
