module Source_branches = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  branch : string;
  source_branches : Source_branches.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show]
