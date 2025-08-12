module Encoding = struct
  let t_of_yojson = function
    | `String "base64" -> Ok "base64"
    | `String "text" -> Ok "text"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  author_email : string option; [@default None]
  author_name : string option; [@default None]
  branch : string;
  commit_message : string;
  content : string;
  encoding : Encoding.t; [@default "text"]
  execute_filemode : bool option; [@default None]
  last_commit_id : string option; [@default None]
  start_branch : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
