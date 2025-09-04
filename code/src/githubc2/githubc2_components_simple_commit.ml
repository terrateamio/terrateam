module Primary = struct
  module Author = struct
    module Primary = struct
      type t = {
        email : string;
        name : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Committer = struct
    module Primary = struct
      type t = {
        email : string;
        name : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    author : Author.t option; [@default None]
    committer : Committer.t option; [@default None]
    id : string;
    message : string;
    timestamp : string;
    tree_id : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
