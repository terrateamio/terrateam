module Primary = struct
  module Package_type = struct
    let t_of_yojson = function
      | `String "container" -> Ok `Container
      | `String "docker" -> Ok `Docker
      | `String "maven" -> Ok `Maven
      | `String "npm" -> Ok `Npm
      | `String "nuget" -> Ok `Nuget
      | `String "rubygems" -> Ok `Rubygems
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Container -> `String "container"
      | `Docker -> `String "docker"
      | `Maven -> `String "maven"
      | `Npm -> `String "npm"
      | `Nuget -> `String "nuget"
      | `Rubygems -> `String "rubygems"

    type t =
      ([ `Container
       | `Docker
       | `Maven
       | `Npm
       | `Nuget
       | `Rubygems
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Visibility = struct
    let t_of_yojson = function
      | `String "private" -> Ok `Private
      | `String "public" -> Ok `Public
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Private -> `String "private"
      | `Public -> `String "public"

    type t =
      ([ `Private
       | `Public
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
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
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
