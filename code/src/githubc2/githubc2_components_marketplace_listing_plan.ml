module Primary = struct
  module Bullets = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Price_model = struct
    let t_of_yojson = function
      | `String "FREE" -> Ok "FREE"
      | `String "FLAT_RATE" -> Ok "FLAT_RATE"
      | `String "PER_UNIT" -> Ok "PER_UNIT"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
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
    price_model : Price_model.t;
    state : string;
    unit_name : string option; [@default None]
    url : string;
    yearly_price_in_cents : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
