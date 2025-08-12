module Action = struct
  module Primary = struct
    type t = {
      button_title : string option; [@default None]
      confirmation_message : string option; [@default None]
      icon : string option; [@default None]
      method_ : string option; [@default None] [@key "method"]
      path : string option; [@default None]
      title : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Illustration = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = {
  action : Action.t option; [@default None]
  details_path : string option; [@default None]
  favicon : string option; [@default None]
  group : string option; [@default None]
  has_details : bool option; [@default None]
  icon : string option; [@default None]
  illustration : Illustration.t option; [@default None]
  label : string option; [@default None]
  text : string option; [@default None]
  tooltip : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
