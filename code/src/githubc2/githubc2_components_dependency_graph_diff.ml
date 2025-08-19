module Items = struct
  module Primary = struct
    module Change_type = struct
      let t_of_yojson = function
        | `String "added" -> Ok "added"
        | `String "removed" -> Ok "removed"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Scope = struct
      let t_of_yojson = function
        | `String "unknown" -> Ok "unknown"
        | `String "runtime" -> Ok "runtime"
        | `String "development" -> Ok "development"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    module Vulnerabilities = struct
      module Items = struct
        module Primary = struct
          type t = {
            advisory_ghsa_id : string;
            advisory_summary : string;
            advisory_url : string;
            severity : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      change_type : Change_type.t;
      ecosystem : string;
      license : string option; [@default None]
      manifest : string;
      name : string;
      package_url : string option; [@default None]
      scope : Scope.t;
      source_repository_url : string option; [@default None]
      version : string;
      vulnerabilities : Vulnerabilities.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
