module Primary = struct
  module Sbom = struct
    module Primary = struct
      module CreationInfo = struct
        module Primary = struct
          module Creators = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            created : string;
            creators : Creators.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Packages = struct
        module Items = struct
          module Primary = struct
            module ExternalRefs = struct
              module Items = struct
                module Primary = struct
                  type t = {
                    referencecategory : string; [@key "referenceCategory"]
                    referencelocator : string; [@key "referenceLocator"]
                    referencetype : string; [@key "referenceType"]
                  }
                  [@@deriving yojson { strict = false; meta = true }, show, eq]
                end

                include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
              end

              type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = {
              spdxid : string option; [@default None] [@key "SPDXID"]
              copyrighttext : string option; [@default None] [@key "copyrightText"]
              downloadlocation : string option; [@default None] [@key "downloadLocation"]
              externalrefs : ExternalRefs.t option; [@default None] [@key "externalRefs"]
              filesanalyzed : bool option; [@default None] [@key "filesAnalyzed"]
              licenseconcluded : string option; [@default None] [@key "licenseConcluded"]
              licensedeclared : string option; [@default None] [@key "licenseDeclared"]
              name : string option; [@default None]
              supplier : string option; [@default None]
              versioninfo : string option; [@default None] [@key "versionInfo"]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Relationships = struct
        module Items = struct
          module Primary = struct
            type t = {
              relatedspdxelement : string option; [@default None] [@key "relatedSpdxElement"]
              relationshiptype : string option; [@default None] [@key "relationshipType"]
              spdxelementid : string option; [@default None] [@key "spdxElementId"]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        spdxid : string; [@key "SPDXID"]
        comment : string option; [@default None]
        creationinfo : CreationInfo.t; [@key "creationInfo"]
        datalicense : string; [@key "dataLicense"]
        documentnamespace : string; [@key "documentNamespace"]
        name : string;
        packages : Packages.t;
        relationships : Relationships.t option; [@default None]
        spdxversion : string; [@key "spdxVersion"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = { sbom : Sbom.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
