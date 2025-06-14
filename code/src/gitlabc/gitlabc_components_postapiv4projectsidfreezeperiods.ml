module Primary = struct
  type t = {
    cron_timezone : string option; [@default None]
    freeze_end : string;
    freeze_start : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
