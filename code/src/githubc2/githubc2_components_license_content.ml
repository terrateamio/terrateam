module Primary = struct
  module Links_ = struct
    module Primary = struct
      type t = {
        git : string option; [@default None]
        html : string option; [@default None]
        self : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    links_ : Links_.t; [@key "_links"]
    content : string;
    download_url : string option; [@default None]
    encoding : string;
    git_url : string option; [@default None]
    html_url : string option; [@default None]
    license : Githubc2_components_nullable_license_simple.t option; [@default None]
    name : string;
    path : string;
    sha : string;
    size : int;
    type_ : string; [@key "type"]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
