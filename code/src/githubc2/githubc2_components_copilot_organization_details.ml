module Primary = struct
  module Cli = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "enabled" -> Ok `Enabled
      | `String "unconfigured" -> Ok `Unconfigured
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `Enabled -> `String "enabled"
      | `Unconfigured -> `String "unconfigured"

    type t =
      ([ `Disabled
       | `Enabled
       | `Unconfigured
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Ide_chat = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "enabled" -> Ok `Enabled
      | `String "unconfigured" -> Ok `Unconfigured
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `Enabled -> `String "enabled"
      | `Unconfigured -> `String "unconfigured"

    type t =
      ([ `Disabled
       | `Enabled
       | `Unconfigured
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Plan_type = struct
    let t_of_yojson = function
      | `String "business" -> Ok `Business
      | `String "enterprise" -> Ok `Enterprise
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Business -> `String "business"
      | `Enterprise -> `String "enterprise"

    type t =
      ([ `Business
       | `Enterprise
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Platform_chat = struct
    let t_of_yojson = function
      | `String "disabled" -> Ok `Disabled
      | `String "enabled" -> Ok `Enabled
      | `String "unconfigured" -> Ok `Unconfigured
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Disabled -> `String "disabled"
      | `Enabled -> `String "enabled"
      | `Unconfigured -> `String "unconfigured"

    type t =
      ([ `Disabled
       | `Enabled
       | `Unconfigured
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Public_code_suggestions = struct
    let t_of_yojson = function
      | `String "allow" -> Ok `Allow
      | `String "block" -> Ok `Block
      | `String "unconfigured" -> Ok `Unconfigured
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Allow -> `String "allow"
      | `Block -> `String "block"
      | `Unconfigured -> `String "unconfigured"

    type t =
      ([ `Allow
       | `Block
       | `Unconfigured
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Seat_management_setting = struct
    let t_of_yojson = function
      | `String "assign_all" -> Ok `Assign_all
      | `String "assign_selected" -> Ok `Assign_selected
      | `String "disabled" -> Ok `Disabled
      | `String "unconfigured" -> Ok `Unconfigured
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Assign_all -> `String "assign_all"
      | `Assign_selected -> `String "assign_selected"
      | `Disabled -> `String "disabled"
      | `Unconfigured -> `String "unconfigured"

    type t =
      ([ `Assign_all
       | `Assign_selected
       | `Disabled
       | `Unconfigured
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
