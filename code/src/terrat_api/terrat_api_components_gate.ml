module All_of = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Any_of = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  all_of : All_of.t option; [@default None]
  any_of : Any_of.t option; [@default None]
  any_of_count : int option; [@default None]
  dir : string option; [@default None]
  token : string;
  workspace : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
