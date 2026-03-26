module Items = struct
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
        | `String "dir" -> Ok `Dir
        | `String "file" -> Ok `File
        | `String "submodule" -> Ok `Submodule
        | `String "symlink" -> Ok `Symlink
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      let t_to_yojson = function
        | `Dir -> `String "dir"
        | `File -> `String "file"
        | `Submodule -> `String "submodule"
        | `Symlink -> `String "symlink"

      type t =
        ([ `Dir
         | `File
         | `Submodule
         | `Symlink
         ]
        [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      content : string option; [@default None]
      download_url : string option; [@default None]
      git_url : string option; [@default None]
      html_url : string option; [@default None]
      name : string;
      path : string;
      sha : string;
      size : int;
      type_ : Type.t; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
