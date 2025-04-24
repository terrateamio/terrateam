module Primary = struct
  type t = {
    description : string option;
    started_at : string;
    status : Githubc2_components_code_scanning_autofix_status.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
