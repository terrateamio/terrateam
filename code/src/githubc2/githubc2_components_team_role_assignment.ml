module Primary = struct
  module Assignment = struct
    let t_of_yojson = function
      | `String "direct" -> Ok `Direct
      | `String "indirect" -> Ok `Indirect
      | `String "mixed" -> Ok `Mixed
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Direct -> `String "direct"
      | `Indirect -> `String "indirect"
      | `Mixed -> `String "mixed"

    type t =
      ([ `Direct
       | `Indirect
       | `Mixed
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Permissions = struct
    module Primary = struct
      type t = {
        admin : bool;
        maintain : bool;
        pull : bool;
        push : bool;
        triage : bool;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    assignment : Assignment.t option; [@default None]
    description : string option; [@default None]
    html_url : string;
    id : int;
    members_url : string;
    name : string;
    node_id : string;
    notification_setting : string option; [@default None]
    parent : Githubc2_components_nullable_team_simple.t option; [@default None]
    permission : string;
    permissions : Permissions.t option; [@default None]
    privacy : string option; [@default None]
    repositories_url : string;
    slug : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
