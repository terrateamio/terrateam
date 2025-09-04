module Primary = struct
  module Error = struct
    module Primary = struct
      type t = { message : string option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    commit : string;
    created_at : string;
    duration : int;
    error : Error.t;
    pusher : Githubc2_components_nullable_simple_user.t option; [@default None]
    status : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
