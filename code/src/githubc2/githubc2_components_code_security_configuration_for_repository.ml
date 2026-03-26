module Primary = struct
  module Status_ = struct
    let t_of_yojson = function
      | `String "attached" -> Ok `Attached
      | `String "attaching" -> Ok `Attaching
      | `String "detached" -> Ok `Detached
      | `String "enforced" -> Ok `Enforced
      | `String "failed" -> Ok `Failed
      | `String "removed" -> Ok `Removed
      | `String "removed_by_enterprise" -> Ok `Removed_by_enterprise
      | `String "updating" -> Ok `Updating
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Attached -> `String "attached"
      | `Attaching -> `String "attaching"
      | `Detached -> `String "detached"
      | `Enforced -> `String "enforced"
      | `Failed -> `String "failed"
      | `Removed -> `String "removed"
      | `Removed_by_enterprise -> `String "removed_by_enterprise"
      | `Updating -> `String "updating"

    type t =
      ([ `Attached
       | `Attaching
       | `Detached
       | `Enforced
       | `Failed
       | `Removed
       | `Removed_by_enterprise
       | `Updating
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    configuration : Githubc2_components_code_security_configuration.t option; [@default None]
    status : Status_.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
