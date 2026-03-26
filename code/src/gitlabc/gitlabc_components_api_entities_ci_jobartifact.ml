module File_format = struct
  let t_of_yojson = function
    | `String "gzip" -> Ok `Gzip
    | `String "raw" -> Ok `Raw
    | `String "zip" -> Ok `Zip
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Gzip -> `String "gzip"
    | `Raw -> `String "raw"
    | `Zip -> `String "zip"

  type t =
    ([ `Gzip
     | `Raw
     | `Zip
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module File_type = struct
  let t_of_yojson = function
    | `String "accessibility" -> Ok `Accessibility
    | `String "annotations" -> Ok `Annotations
    | `String "api_fuzzing" -> Ok `Api_fuzzing
    | `String "archive" -> Ok `Archive
    | `String "browser_performance" -> Ok `Browser_performance
    | `String "cluster_applications" -> Ok `Cluster_applications
    | `String "cluster_image_scanning" -> Ok `Cluster_image_scanning
    | `String "cobertura" -> Ok `Cobertura
    | `String "codequality" -> Ok `Codequality
    | `String "container_scanning" -> Ok `Container_scanning
    | `String "coverage_fuzzing" -> Ok `Coverage_fuzzing
    | `String "cyclonedx" -> Ok `Cyclonedx
    | `String "dast" -> Ok `Dast
    | `String "dependency_scanning" -> Ok `Dependency_scanning
    | `String "dotenv" -> Ok `Dotenv
    | `String "jacoco" -> Ok `Jacoco
    | `String "junit" -> Ok `Junit
    | `String "license_scanning" -> Ok `License_scanning
    | `String "load_performance" -> Ok `Load_performance
    | `String "lsif" -> Ok `Lsif
    | `String "metadata" -> Ok `Metadata
    | `String "metrics" -> Ok `Metrics
    | `String "metrics_referee" -> Ok `Metrics_referee
    | `String "network_referee" -> Ok `Network_referee
    | `String "performance" -> Ok `Performance
    | `String "repository_xray" -> Ok `Repository_xray
    | `String "requirements" -> Ok `Requirements
    | `String "requirements_v2" -> Ok `Requirements_v2
    | `String "sast" -> Ok `Sast
    | `String "secret_detection" -> Ok `Secret_detection
    | `String "terraform" -> Ok `Terraform
    | `String "trace" -> Ok `Trace
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Accessibility -> `String "accessibility"
    | `Annotations -> `String "annotations"
    | `Api_fuzzing -> `String "api_fuzzing"
    | `Archive -> `String "archive"
    | `Browser_performance -> `String "browser_performance"
    | `Cluster_applications -> `String "cluster_applications"
    | `Cluster_image_scanning -> `String "cluster_image_scanning"
    | `Cobertura -> `String "cobertura"
    | `Codequality -> `String "codequality"
    | `Container_scanning -> `String "container_scanning"
    | `Coverage_fuzzing -> `String "coverage_fuzzing"
    | `Cyclonedx -> `String "cyclonedx"
    | `Dast -> `String "dast"
    | `Dependency_scanning -> `String "dependency_scanning"
    | `Dotenv -> `String "dotenv"
    | `Jacoco -> `String "jacoco"
    | `Junit -> `String "junit"
    | `License_scanning -> `String "license_scanning"
    | `Load_performance -> `String "load_performance"
    | `Lsif -> `String "lsif"
    | `Metadata -> `String "metadata"
    | `Metrics -> `String "metrics"
    | `Metrics_referee -> `String "metrics_referee"
    | `Network_referee -> `String "network_referee"
    | `Performance -> `String "performance"
    | `Repository_xray -> `String "repository_xray"
    | `Requirements -> `String "requirements"
    | `Requirements_v2 -> `String "requirements_v2"
    | `Sast -> `String "sast"
    | `Secret_detection -> `String "secret_detection"
    | `Terraform -> `String "terraform"
    | `Trace -> `String "trace"

  type t =
    ([ `Accessibility
     | `Annotations
     | `Api_fuzzing
     | `Archive
     | `Browser_performance
     | `Cluster_applications
     | `Cluster_image_scanning
     | `Cobertura
     | `Codequality
     | `Container_scanning
     | `Coverage_fuzzing
     | `Cyclonedx
     | `Dast
     | `Dependency_scanning
     | `Dotenv
     | `Jacoco
     | `Junit
     | `License_scanning
     | `Load_performance
     | `Lsif
     | `Metadata
     | `Metrics
     | `Metrics_referee
     | `Network_referee
     | `Performance
     | `Repository_xray
     | `Requirements
     | `Requirements_v2
     | `Sast
     | `Secret_detection
     | `Terraform
     | `Trace
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  file_format : File_format.t option; [@default None]
  file_type : File_type.t option; [@default None]
  filename : string option; [@default None]
  size : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
