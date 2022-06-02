module Primary = struct
  module Groups = struct
    module Items = struct
      module Primary = struct
        type t = {
          group_description : string;
          group_id : string;
          group_name : string;
          status : string option; [@default None]
          synced_at : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = { groups : Groups.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
