module File_patterns = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  autoapply : bool; [@default false]
  autoplan : bool; [@default true]
  file_patterns : File_patterns.t; [@default [ "**/*.tf"; "**/*.tfvars" ]]
}
[@@deriving yojson { strict = true; meta = true }, make, show]