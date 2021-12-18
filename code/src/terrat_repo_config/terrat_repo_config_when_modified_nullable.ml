module File_patterns = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  autoapply : bool option; [@default None]
  autoplan : bool option; [@default None]
  file_patterns : File_patterns.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show]
