module Primary = struct
  module Status_ = struct
    let t_of_yojson = function
      | `String "attached" -> Ok "attached"
      | `String "attaching" -> Ok "attaching"
      | `String "detached" -> Ok "detached"
      | `String "removed" -> Ok "removed"
      | `String "enforced" -> Ok "enforced"
      | `String "failed" -> Ok "failed"
      | `String "updating" -> Ok "updating"
      | `String "removed_by_enterprise" -> Ok "removed_by_enterprise"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    repository : Githubc2_components_simple_repository.t option; [@default None]
    status : Status_.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
