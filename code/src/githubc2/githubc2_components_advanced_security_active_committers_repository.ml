module Primary = struct
  module Advanced_security_committers_breakdown = struct
    type t = Githubc2_components_advanced_security_active_committers_user.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    advanced_security_committers : int;
    advanced_security_committers_breakdown : Advanced_security_committers_breakdown.t;
    name : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
