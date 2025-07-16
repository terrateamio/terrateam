type t = {
  active : bool option; [@default None]
  api_url : string option; [@default None]
  integrated : bool option; [@default None]
  project_name : string option; [@default None]
  sentry_external_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
