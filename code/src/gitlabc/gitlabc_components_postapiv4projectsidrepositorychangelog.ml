module Primary = struct
  type t = {
    branch : string option; [@default None]
    config_file : string option; [@default None]
    date : string option; [@default None]
    file : string; [@default "CHANGELOG.md"]
    from : string option; [@default None]
    message : string option; [@default None]
    to_ : string option; [@default None] [@key "to"]
    trailer : string; [@default "Changelog"]
    version : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
