module Assigning_team = struct
  type t =
    | Team of Githubc2_components_team.t
    | Enterprise_team of Githubc2_components_enterprise_team.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [
         (fun v -> map (fun v -> Team v) (Githubc2_components_team.of_yojson v));
         (fun v ->
           map (fun v -> Enterprise_team v) (Githubc2_components_enterprise_team.of_yojson v));
       ])

  let to_yojson = function
    | Team v -> Githubc2_components_team.to_yojson v
    | Enterprise_team v -> Githubc2_components_enterprise_team.to_yojson v
end

module Plan_type = struct
  let t_of_yojson = function
    | `String "business" -> Ok `Business
    | `String "enterprise" -> Ok `Enterprise
    | `String "unknown" -> Ok `Unknown
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Business -> `String "business"
    | `Enterprise -> `String "enterprise"
    | `Unknown -> `String "unknown"

  type t =
    ([ `Business
     | `Enterprise
     | `Unknown
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  assignee : Githubc2_components_simple_user.t;
  assigning_team : Assigning_team.t option; [@default None]
  created_at : string;
  last_activity_at : string option; [@default None]
  last_activity_editor : string option; [@default None]
  organization : Githubc2_components_nullable_organization_simple.t option; [@default None]
  pending_cancellation_date : string option; [@default None]
  plan_type : Plan_type.t option; [@default None]
  updated_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
