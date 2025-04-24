module Primary = struct
  module Properties = struct
    type t = Githubc2_components_custom_property_value.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    properties : Properties.t;
    repository_full_name : string;
    repository_id : int;
    repository_name : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
