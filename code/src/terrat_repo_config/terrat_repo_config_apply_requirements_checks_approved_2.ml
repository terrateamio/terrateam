module All_of = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Any_of = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  all_of : All_of.t option; [@default None]
  any_of : Any_of.t option; [@default None]
  any_of_count : int; [@default 1]
  enabled : bool; [@default false]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
