module Primary = struct
  type t = {
    content : string;
    dry_run : bool; [@default false]
    include_jobs : bool option; [@default None]
    ref_ : string option; [@default None] [@key "ref"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
