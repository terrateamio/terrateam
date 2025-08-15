module Primary = struct
  module Notification_setting = struct
    let t_of_yojson = function
      | `String "notifications_enabled" -> Ok "notifications_enabled"
      | `String "notifications_disabled" -> Ok "notifications_disabled"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Parent = struct
    module Primary = struct
      module Notification_setting = struct
        let t_of_yojson = function
          | `String "notifications_enabled" -> Ok "notifications_enabled"
          | `String "notifications_disabled" -> Ok "notifications_disabled"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Privacy = struct
        let t_of_yojson = function
          | `String "open" -> Ok "open"
          | `String "closed" -> Ok "closed"
          | `String "secret" -> Ok "secret"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        description : string option; [@default None]
        html_url : string;
        id : int;
        members_url : string;
        name : string;
        node_id : string;
        notification_setting : Notification_setting.t;
        permission : string;
        privacy : Privacy.t;
        repositories_url : string;
        slug : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Privacy = struct
    let t_of_yojson = function
      | `String "open" -> Ok "open"
      | `String "closed" -> Ok "closed"
      | `String "secret" -> Ok "secret"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    deleted : bool option; [@default None]
    description : string option; [@default None]
    html_url : string option; [@default None]
    id : int;
    members_url : string option; [@default None]
    name : string;
    node_id : string option; [@default None]
    notification_setting : Notification_setting.t option; [@default None]
    parent : Parent.t option; [@default None]
    permission : string option; [@default None]
    privacy : Privacy.t option; [@default None]
    repositories_url : string option; [@default None]
    slug : string option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
