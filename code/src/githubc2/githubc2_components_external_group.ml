module Primary = struct
  module Members = struct
    module Items = struct
      module Primary = struct
        type t = {
          member_email : string;
          member_id : int;
          member_login : string;
          member_name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Teams = struct
    module Items = struct
      module Primary = struct
        type t = {
          team_id : int;
          team_name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    group_id : int;
    group_name : string;
    members : Members.t;
    teams : Teams.t;
    updated_at : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
