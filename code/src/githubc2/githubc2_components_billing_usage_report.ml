module Primary = struct
  module UsageItems = struct
    module Items = struct
      module Primary = struct
        type t = {
          date : string;
          discountamount : float; [@key "discountAmount"]
          grossamount : float; [@key "grossAmount"]
          netamount : float; [@key "netAmount"]
          organizationname : string; [@key "organizationName"]
          priceperunit : float; [@key "pricePerUnit"]
          product : string;
          quantity : int;
          repositoryname : string option; [@default None] [@key "repositoryName"]
          sku : string;
          unittype : string; [@key "unitType"]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { usageitems : UsageItems.t option [@default None] [@key "usageItems"] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
