module Primary = struct
  module Resources = struct
    module Items = struct
      module Primary = struct
        module Emails = struct
          module Items = struct
            module Primary = struct
              type t = {
                primary : bool option; [@default None]
                type_ : string option; [@default None] [@key "type"]
                value : string option; [@default None]
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
              type t = { value : string option [@default None] }
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
              familyname : string option; [@default None] [@key "familyName"]
              givenname : string option; [@default None] [@key "givenName"]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Schemas = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          active : bool option; [@default None]
          emails : Emails.t option; [@default None]
          externalid : string option; [@default None] [@key "externalId"]
          groups : Groups.t option; [@default None]
          id : string;
          meta : Meta.t option; [@default None]
          name : Name.t option; [@default None]
          schemas : Schemas.t;
          username : string option; [@default None] [@key "userName"]
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
    resources : Resources.t; [@key "Resources"]
    itemsperpage : float; [@key "itemsPerPage"]
    schemas : Schemas.t;
    startindex : float; [@key "startIndex"]
    totalresults : float; [@key "totalResults"]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
