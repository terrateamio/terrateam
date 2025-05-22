module Primary = struct
  module Models = struct
    module Items = struct
      module Primary = struct
        type t = {
          custom_model_training_date : string option; [@default None]
          is_custom_model : bool option; [@default None]
          name : string option; [@default None]
          total_chats : int option; [@default None]
          total_engaged_users : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    models : Models.t option; [@default None]
    total_engaged_users : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
