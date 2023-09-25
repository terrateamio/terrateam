module Primary = struct
  module Activity_type = struct
    let t_of_yojson = function
      | `String "push" -> Ok "push"
      | `String "force_push" -> Ok "force_push"
      | `String "branch_deletion" -> Ok "branch_deletion"
      | `String "branch_creation" -> Ok "branch_creation"
      | `String "pr_merge" -> Ok "pr_merge"
      | `String "merge_queue_merge" -> Ok "merge_queue_merge"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    activity_type : Activity_type.t;
    actor : Githubc2_components_nullable_simple_user.t option;
    after : string;
    before : string;
    id : int;
    node_id : string;
    ref_ : string; [@key "ref"]
    timestamp : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
