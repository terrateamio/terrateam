module Delete_extra_args = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Fetch_extra_args = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Method = struct
  let t_of_yojson = function
    | `String "s3" -> Ok `S3
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `S3 -> `String "s3"

  type t = ([ `S3 ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Store_extra_args = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  access_key_id : string option; [@default None]
  bucket : string;
  delete_extra_args : Delete_extra_args.t option; [@default None]
  delete_used_plans : bool; [@default true]
  fetch_extra_args : Fetch_extra_args.t option; [@default None]
  method_ : Method.t; [@key "method"]
  path : string option; [@default None]
  region : string;
  secret_access_key : string option; [@default None]
  store_extra_args : Store_extra_args.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
