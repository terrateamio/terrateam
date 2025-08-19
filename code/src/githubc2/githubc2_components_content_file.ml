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

  module Type = struct
    let t_of_yojson = function
      | `String "file" -> Ok "file"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    links_ : Links_.t; [@key "_links"]
    content : string;
    download_url : string option; [@default None]
    encoding : string;
    git_url : string option; [@default None]
    html_url : string option; [@default None]
    name : string;
    path : string;
    sha : string;
    size : int;
    submodule_git_url : string option; [@default None]
    target : string option; [@default None]
    type_ : Type.t; [@key "type"]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
