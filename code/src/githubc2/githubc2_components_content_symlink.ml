module Primary = struct
  module Links_ = struct
    module Primary = struct
      type t = {
        git : string option;
        html : string option;
        self : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    links_ : Links_.t; [@key "_links"]
    download_url : string option;
    git_url : string option;
    html_url : string option;
    name : string;
    path : string;
    sha : string;
    size : int;
    target : string;
    type_ : string; [@key "type"]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
