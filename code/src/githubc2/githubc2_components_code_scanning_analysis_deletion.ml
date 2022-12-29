module Primary = struct
  type t = {
    confirm_delete_url : string option;
    next_analysis_url : string option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
