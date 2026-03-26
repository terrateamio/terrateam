module Primary = struct
  module Advanced_security = struct
    module Primary = struct
      module Status_ = struct
        let t_of_yojson = function
          | `String "disabled" -> Ok `Disabled
          | `String "enabled" -> Ok `Enabled
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Disabled -> `String "disabled"
          | `Enabled -> `String "enabled"

        type t =
          ([ `Disabled
           | `Enabled
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Code_security = struct
    module Primary = struct
      module Status_ = struct
        let t_of_yojson = function
          | `String "disabled" -> Ok `Disabled
          | `String "enabled" -> Ok `Enabled
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Disabled -> `String "disabled"
          | `Enabled -> `String "enabled"

        type t =
          ([ `Disabled
           | `Enabled
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
          | `String "disabled" -> Ok `Disabled
          | `String "enabled" -> Ok `Enabled
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Disabled -> `String "disabled"
          | `Enabled -> `String "enabled"

        type t =
          ([ `Disabled
           | `Enabled
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
          | `String "disabled" -> Ok `Disabled
          | `String "enabled" -> Ok `Enabled
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Disabled -> `String "disabled"
          | `Enabled -> `String "enabled"

        type t =
          ([ `Disabled
           | `Enabled
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning_ai_detection = struct
    module Primary = struct
      module Status_ = struct
        let t_of_yojson = function
          | `String "disabled" -> Ok `Disabled
          | `String "enabled" -> Ok `Enabled
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Disabled -> `String "disabled"
          | `Enabled -> `String "enabled"

        type t =
          ([ `Disabled
           | `Enabled
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Secret_scanning_non_provider_patterns = struct
    module Primary = struct
      module Status_ = struct
        let t_of_yojson = function
          | `String "disabled" -> Ok `Disabled
          | `String "enabled" -> Ok `Enabled
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Disabled -> `String "disabled"
          | `Enabled -> `String "enabled"

        type t =
          ([ `Disabled
           | `Enabled
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
          | `String "disabled" -> Ok `Disabled
          | `String "enabled" -> Ok `Enabled
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Disabled -> `String "disabled"
          | `Enabled -> `String "enabled"

        type t =
          ([ `Disabled
           | `Enabled
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { status : Status_.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    advanced_security : Advanced_security.t option; [@default None]
    code_security : Code_security.t option; [@default None]
    dependabot_security_updates : Dependabot_security_updates.t option; [@default None]
    secret_scanning : Secret_scanning.t option; [@default None]
    secret_scanning_ai_detection : Secret_scanning_ai_detection.t option; [@default None]
    secret_scanning_non_provider_patterns : Secret_scanning_non_provider_patterns.t option;
        [@default None]
    secret_scanning_push_protection : Secret_scanning_push_protection.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
