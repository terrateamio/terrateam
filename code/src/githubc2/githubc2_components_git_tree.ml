module Primary = struct
  module Tree = struct
    module Items = struct
      module Primary = struct
        type t = {
          mode : string option; [@default None]
          path : string option; [@default None]
          sha : string option; [@default None]
          size : int option; [@default None]
          type_ : string option; [@default None] [@key "type"]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    sha : string;
    tree : Tree.t;
    truncated : bool;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
