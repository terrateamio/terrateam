module Primary = struct
  module Tier = struct
    module Primary = struct
      module From = struct
        module Primary = struct
          type t = {
            created_at : string;
            description : string;
            is_custom_ammount : bool option; [@default None]
            is_custom_amount : bool option; [@default None]
            is_one_time : bool;
            monthly_price_in_cents : int;
            monthly_price_in_dollars : int;
            name : string;
            node_id : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = { from : From.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = { tier : Tier.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
