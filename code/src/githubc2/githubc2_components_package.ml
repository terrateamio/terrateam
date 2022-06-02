module Primary = struct
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
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Visibility = struct
    let t_of_yojson = function
      | `String "private" -> Ok "private"
      | `String "public" -> Ok "public"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    created_at : string;
    html_url : string;
    id : int;
    name : string;
    owner : Githubc2_components_nullable_simple_user.t option; [@default None]
    package_type : Package_type.t;
    repository : Githubc2_components_nullable_minimal_repository.t option; [@default None]
    updated_at : string;
    url : string;
    version_count : int;
    visibility : Visibility.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
