module Primary = struct
  module Parameters = struct
    module Primary = struct
      module Workflows = struct
        type t = Githubc2_components_repository_rule_params_workflow_file_reference.t list
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        do_not_enforce_on_create : bool option; [@default None]
        workflows : Workflows.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Type = struct
    let t_of_yojson = function
      | `String "workflows" -> Ok "workflows"
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
