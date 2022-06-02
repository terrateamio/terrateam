module Primary = struct
  type t = {
    end_column : int option; [@default None]
    end_line : int option; [@default None]
    path : string option; [@default None]
    start_column : int option; [@default None]
    start_line : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
