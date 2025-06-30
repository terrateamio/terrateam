module Primary = struct
  type t = {
    cadence : string option; [@default None]
    enabled : string option; [@default None]
    keep_n : string option; [@default None]
    name_regex : string option; [@default None]
    name_regex_keep : string option; [@default None]
    next_run_at : string option; [@default None]
    older_than : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
