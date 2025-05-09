module Primary = struct
  module Cli = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "unconfigured" -> Ok "unconfigured"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Ide_chat = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "unconfigured" -> Ok "unconfigured"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Plan_type = struct
    let t_of_yojson = function
      | `String "business" -> Ok "business"
      | `String "enterprise" -> Ok "enterprise"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Platform_chat = struct
    let t_of_yojson = function
      | `String "enabled" -> Ok "enabled"
      | `String "disabled" -> Ok "disabled"
      | `String "unconfigured" -> Ok "unconfigured"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Public_code_suggestions = struct
    let t_of_yojson = function
      | `String "allow" -> Ok "allow"
      | `String "block" -> Ok "block"
      | `String "unconfigured" -> Ok "unconfigured"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Seat_management_setting = struct
    let t_of_yojson = function
      | `String "assign_all" -> Ok "assign_all"
      | `String "assign_selected" -> Ok "assign_selected"
      | `String "disabled" -> Ok "disabled"
      | `String "unconfigured" -> Ok "unconfigured"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    cli : Cli.t option; [@default None]
    ide_chat : Ide_chat.t option; [@default None]
    plan_type : Plan_type.t option; [@default None]
    platform_chat : Platform_chat.t option; [@default None]
    public_code_suggestions : Public_code_suggestions.t;
    seat_breakdown : Githubc2_components_copilot_organization_seat_breakdown.t;
    seat_management_setting : Seat_management_setting.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
