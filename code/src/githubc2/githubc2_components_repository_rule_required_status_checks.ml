module Primary = struct
  module Parameters = struct
    module Primary = struct
      module Required_status_checks = struct
        type t = Githubc2_components_repository_rule_params_status_check_configuration.t list
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        required_status_checks : Required_status_checks.t;
        strict_required_status_checks_policy : bool;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Type = struct
    let t_of_yojson = function
      | `String "required_status_checks" -> Ok "required_status_checks"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    parameters : Parameters.t option; [@default None]
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
