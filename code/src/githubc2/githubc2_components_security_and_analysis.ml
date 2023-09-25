module Primary = struct
  module Advanced_security = struct
    module Primary = struct
      module Status_ = struct
        let t_of_yojson = function
          | `String "enabled" -> Ok "enabled"
          | `String "disabled" -> Ok "disabled"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Dependabot_security_updates = struct
    module Primary = struct
      module Status_ = struct
        let t_of_yojson = function
          | `String "enabled" -> Ok "enabled"
          | `String "disabled" -> Ok "disabled"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning = struct
    module Primary = struct
      module Status_ = struct
        let t_of_yojson = function
          | `String "enabled" -> Ok "enabled"
          | `String "disabled" -> Ok "disabled"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning_push_protection = struct
    module Primary = struct
      module Status_ = struct
        let t_of_yojson = function
          | `String "enabled" -> Ok "enabled"
          | `String "disabled" -> Ok "disabled"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    advanced_security : Advanced_security.t option; [@default None]
    dependabot_security_updates : Dependabot_security_updates.t option; [@default None]
    secret_scanning : Secret_scanning.t option; [@default None]
    secret_scanning_push_protection : Secret_scanning_push_protection.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
