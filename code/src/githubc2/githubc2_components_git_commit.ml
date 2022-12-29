module Primary = struct
  module Author = struct
    module Primary = struct
      type t = {
        date : string;
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
        date : string;
        email : string;
        name : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Parents = struct
    module Items = struct
      module Primary = struct
        type t = {
          html_url : string;
          sha : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Tree = struct
    module Primary = struct
      type t = {
        sha : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Verification_ = struct
    module Primary = struct
      type t = {
        payload : string option;
        reason : string;
        signature : string option;
        verified : bool;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    author : Author.t;
    committer : Committer.t;
    html_url : string;
    message : string;
    node_id : string;
    parents : Parents.t;
    sha : string;
    tree : Tree.t;
    url : string;
    verification : Verification_.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
