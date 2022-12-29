module Primary = struct
  module Base = struct
    module Primary = struct
      module Repo = struct
        module Primary = struct
          type t = {
            id : int;
            name : string;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        ref_ : string; [@key "ref"]
        repo : Repo.t;
        sha : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Head = struct
    module Primary = struct
      module Repo = struct
        module Primary = struct
          type t = {
            id : int;
            name : string;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        ref_ : string; [@key "ref"]
        repo : Repo.t;
        sha : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    base : Base.t;
    head : Head.t;
    id : int;
    number : int;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
