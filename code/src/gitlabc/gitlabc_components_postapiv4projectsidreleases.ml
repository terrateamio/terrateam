module Assets = struct
  module Primary = struct
    module Links = struct
      module Items = struct
        module Primary = struct
          type t = {
            direct_asset_path : string option; [@default None]
            filepath : string option; [@default None]
            link_type : string option; [@default None]
            name : string;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = { links : Links.t option [@default None] }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Milestones = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  assets : Assets.t option; [@default None]
  description : string option; [@default None]
  legacy_catalog_publish : bool option; [@default None]
  milestone_ids : string option; [@default None]
  milestones : Milestones.t option; [@default None]
  name : string option; [@default None]
  ref_ : string option; [@default None] [@key "ref"]
  released_at : string option; [@default None]
  tag_message : string option; [@default None]
  tag_name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
