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

  module Entries = struct
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

        type t = {
          links_ : Links_.t; [@key "_links"]
          download_url : string option; [@default None]
          git_url : string option; [@default None]
          html_url : string option; [@default None]
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
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    links_ : Links_.t; [@key "_links"]
    content : string option; [@default None]
    download_url : string option; [@default None]
    encoding : string option; [@default None]
    entries : Entries.t option; [@default None]
    git_url : string option; [@default None]
    html_url : string option; [@default None]
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
