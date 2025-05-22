module Primary = struct
  module Allowed_values = struct
    type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Default_value = struct
    module V0 = struct
      type t = string option [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module V1 = struct
      type t = string list option [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t =
      | V0 of V0.t
      | V1 of V1.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
           (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
         ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
      | V1 v -> V1.to_yojson v
  end

  module Source_type = struct
    let t_of_yojson = function
      | `String "organization" -> Ok "organization"
      | `String "enterprise" -> Ok "enterprise"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Value_type = struct
    let t_of_yojson = function
      | `String "string" -> Ok "string"
      | `String "single_select" -> Ok "single_select"
      | `String "multi_select" -> Ok "multi_select"
      | `String "true_false" -> Ok "true_false"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Values_editable_by = struct
    let t_of_yojson = function
      | `String "org_actors" -> Ok "org_actors"
      | `String "org_and_repo_actors" -> Ok "org_and_repo_actors"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    allowed_values : Allowed_values.t option; [@default None]
    default_value : Default_value.t option; [@default None]
    description : string option; [@default None]
    property_name : string;
    required : bool option; [@default None]
    source_type : Source_type.t option; [@default None]
    url : string option; [@default None]
    value_type : Value_type.t;
    values_editable_by : Values_editable_by.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
