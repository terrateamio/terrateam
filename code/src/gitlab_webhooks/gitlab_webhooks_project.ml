type t = {
  default_branch : string;
  id : int;
  name : string;
  namespace : string;
  path_with_namespace : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
