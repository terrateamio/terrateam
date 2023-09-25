module Assignee = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

module Assigning_team = struct
  type t = Team of Githubc2_components_team.t [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [ (fun v -> map (fun v -> Team v) (Githubc2_components_team.of_yojson v)) ])

  let to_yojson = function
    | Team v -> Githubc2_components_team.to_yojson v
end

type t = {
  assignee : Assignee.t;
  assigning_team : Assigning_team.t option; [@default None]
  created_at : string;
  last_activity_at : string option; [@default None]
  last_activity_editor : string option; [@default None]
  pending_cancellation_date : string option; [@default None]
  updated_at : string option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
