module Primary = struct
  type t = {
    branch : string;
    dry_run : bool; [@default false]
    message : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
