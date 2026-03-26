module Primary = struct
  module Activity_type = struct
    let t_of_yojson = function
      | `String "branch_creation" -> Ok `Branch_creation
      | `String "branch_deletion" -> Ok `Branch_deletion
      | `String "force_push" -> Ok `Force_push
      | `String "merge_queue_merge" -> Ok `Merge_queue_merge
      | `String "pr_merge" -> Ok `Pr_merge
      | `String "push" -> Ok `Push
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Branch_creation -> `String "branch_creation"
      | `Branch_deletion -> `String "branch_deletion"
      | `Force_push -> `String "force_push"
      | `Merge_queue_merge -> `String "merge_queue_merge"
      | `Pr_merge -> `String "pr_merge"
      | `Push -> `String "push"

    type t =
      ([ `Branch_creation
       | `Branch_deletion
       | `Force_push
       | `Merge_queue_merge
       | `Pr_merge
       | `Push
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    activity_type : Activity_type.t;
    actor : Githubc2_components_nullable_simple_user.t option; [@default None]
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
