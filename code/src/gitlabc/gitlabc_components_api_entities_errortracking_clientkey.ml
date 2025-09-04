type t = {
  active : bool option; [@default None]
  id : int option; [@default None]
  public_key : string option; [@default None]
  sentry_dsn : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
