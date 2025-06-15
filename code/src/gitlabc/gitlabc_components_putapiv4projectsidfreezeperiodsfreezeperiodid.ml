module Primary = struct
  type t = {
    cron_timezone : string option; [@default None]
    freeze_end : string option; [@default None]
    freeze_start : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
