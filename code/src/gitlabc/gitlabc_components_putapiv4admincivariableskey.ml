module Primary = struct
  module Variable_type = struct
    let t_of_yojson = function
      | `String "env_var" -> Ok "env_var"
      | `String "file" -> Ok "file"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    description : string option; [@default None]
    masked : bool option; [@default None]
    protected : bool option; [@default None]
    raw : bool option; [@default None]
    value : string option; [@default None]
    variable_type : Variable_type.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
