module On_change = struct
  module Can_apply_after = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { can_apply_after : Can_apply_after.t option [@default None] }
  [@@deriving yojson { strict = true; meta = true }, make, show, eq]
end

module Variables = struct
  module Additional = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

type t = {
  on_change : On_change.t option; [@default None]
  tag_query : string;
  variables : Variables.t option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
