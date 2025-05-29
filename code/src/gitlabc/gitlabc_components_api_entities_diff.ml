module Primary = struct
  type t = {
    a_mode : string option; [@default None]
    b_mode : string option; [@default None]
    deleted_file : bool option; [@default None]
    diff : string option; [@default None]
    generated_file : bool option; [@default None]
    new_file : bool option; [@default None]
    new_path : string option; [@default None]
    old_path : string option; [@default None]
    renamed_file : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
