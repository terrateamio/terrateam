module Primary = struct
  type t = {
    description : string option; [@default None]
    environment_scope : string option; [@default None]
    hidden : bool option; [@default None]
    key : string option; [@default None]
    masked : bool option; [@default None]
    protected : bool option; [@default None]
    raw : bool option; [@default None]
    value : string option; [@default None]
    variable_type : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
