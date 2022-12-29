module Primary = struct
  module Teams = struct
    type t = Githubc2_components_team.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Users = struct
    type t = Githubc2_components_simple_user.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    teams : Teams.t;
    users : Users.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
