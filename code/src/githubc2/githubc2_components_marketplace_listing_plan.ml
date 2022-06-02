module Primary = struct
  module Bullets = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    accounts_url : string;
    bullets : Bullets.t;
    description : string;
    has_free_trial : bool;
    id : int;
    monthly_price_in_cents : int;
    name : string;
    number : int;
    price_model : string;
    state : string;
    unit_name : string option;
    url : string;
    yearly_price_in_cents : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
