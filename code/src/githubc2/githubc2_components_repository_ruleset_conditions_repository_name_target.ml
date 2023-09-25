module Primary = struct
  module Repository_name = struct
    module Primary = struct
      module Exclude = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Include = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        exclude : Exclude.t option; [@default None]
        include_ : Include.t option; [@default None] [@key "include"]
        protected : bool option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = { repository_name : Repository_name.t }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
