module Primary = struct
  type t = {
    days_left_in_billing_cycle : int;
    estimated_paid_storage_for_month : int;
    estimated_storage_for_month : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
