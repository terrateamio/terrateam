module Primary = struct
  module Error = struct
    module Primary = struct
      type t = { message : string option } [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    commit : string;
    created_at : string;
    duration : int;
    error : Error.t;
    pusher : Githubc2_components_nullable_simple_user.t option;
    status : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
