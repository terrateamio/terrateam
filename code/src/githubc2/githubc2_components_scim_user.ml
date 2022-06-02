module Primary = struct
  module Emails = struct
    module Items = struct
      module Primary = struct
        type t = {
          primary : bool option; [@default None]
          value : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Groups = struct
    module Items = struct
      module Primary = struct
        type t = {
          display : string option; [@default None]
          value : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Meta = struct
    module Primary = struct
      type t = {
        created : string option; [@default None]
        lastmodified : string option; [@default None] [@key "lastModified"]
        location : string option; [@default None]
        resourcetype : string option; [@default None] [@key "resourceType"]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Name = struct
    module Primary = struct
      type t = {
        familyname : string option; [@key "familyName"]
        formatted : string option; [@default None]
        givenname : string option; [@key "givenName"]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Operations = struct
    module Items = struct
      module Primary = struct
        module Op = struct
          let t_of_yojson = function
            | `String "add" -> Ok "add"
            | `String "remove" -> Ok "remove"
            | `String "replace" -> Ok "replace"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        module Value = struct
          module V0 = struct
            type t = string [@@deriving yojson { strict = false; meta = true }, show]
          end

          module V1 = struct
            include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
          end

          module V2 = struct
            module Items = struct
              type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t =
            | V0 of V0.t
            | V1 of V1.t
            | V2 of V2.t
          [@@deriving show]

          let of_yojson =
            Json_schema.one_of
              (let open CCResult in
              [
                (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
              ])

          let to_yojson = function
            | V0 v -> V0.to_yojson v
            | V1 v -> V1.to_yojson v
            | V2 v -> V2.to_yojson v
        end

        type t = {
          op : Op.t;
          path : string option; [@default None]
          value : Value.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Schemas = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    active : bool;
    displayname : string option; [@default None] [@key "displayName"]
    emails : Emails.t;
    externalid : string option; [@key "externalId"]
    groups : Groups.t option; [@default None]
    id : string;
    meta : Meta.t;
    name : Name.t;
    operations : Operations.t option; [@default None]
    organization_id : int option; [@default None]
    schemas : Schemas.t;
    username : string option; [@key "userName"]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
