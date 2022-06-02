module Primary = struct
  type t = {
    code : int option;
    message : string option;
    status : string option;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
