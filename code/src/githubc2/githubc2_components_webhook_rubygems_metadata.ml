module Primary = struct
  module Dependencies = struct
    module Items = struct
      module Additional = struct
        type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Metadata_ = struct
    module Additional = struct
      type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
  end

  module Version_info = struct
    module Primary = struct
      type t = { version : string option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    commit_oid : string option; [@default None]
    dependencies : Dependencies.t option; [@default None]
    description : string option; [@default None]
    homepage : string option; [@default None]
    metadata : Metadata_.t option; [@default None]
    name : string option; [@default None]
    platform : string option; [@default None]
    readme : string option; [@default None]
    repo : string option; [@default None]
    version_info : Version_info.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
