type t = {
  active : string option; [@default None]
  extern_uid : string option; [@default None]
  group_id : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
