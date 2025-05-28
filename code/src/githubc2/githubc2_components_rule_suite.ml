module Primary = struct
  module Evaluation_result = struct
    let t_of_yojson = function
      | `String "pass" -> Ok "pass"
      | `String "fail" -> Ok "fail"
      | `String "bypass" -> Ok "bypass"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Result = struct
    let t_of_yojson = function
      | `String "pass" -> Ok "pass"
      | `String "fail" -> Ok "fail"
      | `String "bypass" -> Ok "bypass"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Rule_evaluations = struct
    module Items = struct
      module Primary = struct
        module Enforcement = struct
          let t_of_yojson = function
            | `String "active" -> Ok "active"
            | `String "evaluate" -> Ok "evaluate"
            | `String "deleted ruleset" -> Ok "deleted ruleset"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Result = struct
          let t_of_yojson = function
            | `String "pass" -> Ok "pass"
            | `String "fail" -> Ok "fail"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Rule_source = struct
          module Primary = struct
            type t = {
              id : int option; [@default None]
              name : string option; [@default None]
              type_ : string option; [@default None] [@key "type"]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          details : string option; [@default None]
          enforcement : Enforcement.t option; [@default None]
          result : Result.t option; [@default None]
          rule_source : Rule_source.t option; [@default None]
          rule_type : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    actor_id : int option; [@default None]
    actor_name : string option; [@default None]
    after_sha : string option; [@default None]
    before_sha : string option; [@default None]
    evaluation_result : Evaluation_result.t option; [@default None]
    id : int option; [@default None]
    pushed_at : string option; [@default None]
    ref_ : string option; [@default None] [@key "ref"]
    repository_id : int option; [@default None]
    repository_name : string option; [@default None]
    result : Result.t option; [@default None]
    rule_evaluations : Rule_evaluations.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
