module Primary = struct
  module Metadata_ = struct
    module Primary = struct
      module Container = struct
        module Primary = struct
          module Tags = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { tags : Tags.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Docker = struct
        module Primary = struct
          module Tag_ = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { tag : Tag_.t option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Package_type = struct
        let t_of_yojson = function
          | `String "npm" -> Ok "npm"
          | `String "maven" -> Ok "maven"
          | `String "rubygems" -> Ok "rubygems"
          | `String "docker" -> Ok "docker"
          | `String "nuget" -> Ok "nuget"
          | `String "container" -> Ok "container"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        container : Container.t option; [@default None]
        docker : Docker.t option; [@default None]
        package_type : Package_type.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    created_at : string;
    deleted_at : string option; [@default None]
    description : string option; [@default None]
    html_url : string option; [@default None]
    id : int;
    license : string option; [@default None]
    metadata : Metadata_.t option; [@default None]
    name : string;
    package_html_url : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
