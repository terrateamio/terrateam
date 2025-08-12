module All_of = struct
  module Primary = struct
    module Actor_ = struct
      module Primary = struct
        type t = {
          id : int option; [@default None]
          type_ : string option; [@default None] [@key "type"]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module State = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = {
      actor : Actor_.t;
      state : State.t;
      updated_at : string;
      version_id : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module T = struct
  module Primary = struct
    module Actor_ = struct
      module Primary = struct
        type t = {
          id : int option; [@default None]
          type_ : string option; [@default None] [@key "type"]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module State = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = {
      actor : Actor_.t;
      state : State.t;
      updated_at : string;
      version_id : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

let of_yojson json =
  let open CCResult in
  flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
