module Primary = struct
  type t = {
    duration : float option; [@default None]
    id : string;
    start_date : string option; [@default None]
    title : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
