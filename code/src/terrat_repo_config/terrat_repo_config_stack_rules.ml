module Apply_after = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Modified_by = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Plan_after = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  apply_after : Apply_after.t option; [@default None]
  auto_apply : bool option; [@default None]
  modified_by : Modified_by.t option; [@default None]
  plan_after : Plan_after.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
