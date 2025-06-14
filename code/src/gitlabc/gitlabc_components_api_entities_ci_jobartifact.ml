module Primary = struct
  module File_format = struct
    let t_of_yojson = function
      | `String "raw" -> Ok "raw"
      | `String "zip" -> Ok "zip"
      | `String "gzip" -> Ok "gzip"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module File_type = struct
    let t_of_yojson = function
      | `String "archive" -> Ok "archive"
      | `String "metadata" -> Ok "metadata"
      | `String "trace" -> Ok "trace"
      | `String "junit" -> Ok "junit"
      | `String "sast" -> Ok "sast"
      | `String "dependency_scanning" -> Ok "dependency_scanning"
      | `String "container_scanning" -> Ok "container_scanning"
      | `String "dast" -> Ok "dast"
      | `String "codequality" -> Ok "codequality"
      | `String "license_scanning" -> Ok "license_scanning"
      | `String "performance" -> Ok "performance"
      | `String "metrics" -> Ok "metrics"
      | `String "metrics_referee" -> Ok "metrics_referee"
      | `String "network_referee" -> Ok "network_referee"
      | `String "lsif" -> Ok "lsif"
      | `String "dotenv" -> Ok "dotenv"
      | `String "cobertura" -> Ok "cobertura"
      | `String "terraform" -> Ok "terraform"
      | `String "accessibility" -> Ok "accessibility"
      | `String "cluster_applications" -> Ok "cluster_applications"
      | `String "secret_detection" -> Ok "secret_detection"
      | `String "requirements" -> Ok "requirements"
      | `String "coverage_fuzzing" -> Ok "coverage_fuzzing"
      | `String "browser_performance" -> Ok "browser_performance"
      | `String "load_performance" -> Ok "load_performance"
      | `String "api_fuzzing" -> Ok "api_fuzzing"
      | `String "cluster_image_scanning" -> Ok "cluster_image_scanning"
      | `String "cyclonedx" -> Ok "cyclonedx"
      | `String "requirements_v2" -> Ok "requirements_v2"
      | `String "annotations" -> Ok "annotations"
      | `String "repository_xray" -> Ok "repository_xray"
      | `String "jacoco" -> Ok "jacoco"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    file_format : File_format.t option; [@default None]
    file_type : File_type.t option; [@default None]
    filename : string option; [@default None]
    size : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
