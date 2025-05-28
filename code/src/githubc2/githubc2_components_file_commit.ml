module Primary = struct
  module Commit_ = struct
    module Primary = struct
      module Author = struct
        module Primary = struct
          type t = {
            date : string option; [@default None]
            email : string option; [@default None]
            name : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Committer = struct
        module Primary = struct
          type t = {
            date : string option; [@default None]
            email : string option; [@default None]
            name : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Parents = struct
        module Items = struct
          module Primary = struct
            type t = {
              html_url : string option; [@default None]
              sha : string option; [@default None]
              url : string option; [@default None]
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
            sha : string option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Verification_ = struct
        module Primary = struct
          type t = {
            payload : string option; [@default None]
            reason : string option; [@default None]
            signature : string option; [@default None]
            verified : bool option; [@default None]
            verified_at : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        author : Author.t option; [@default None]
        committer : Committer.t option; [@default None]
        html_url : string option; [@default None]
        message : string option; [@default None]
        node_id : string option; [@default None]
        parents : Parents.t option; [@default None]
        sha : string option; [@default None]
        tree : Tree.t option; [@default None]
        url : string option; [@default None]
        verification : Verification_.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Content = struct
    module Primary = struct
      module Links_ = struct
        module Primary = struct
          type t = {
            git : string option; [@default None]
            html : string option; [@default None]
            self : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        links_ : Links_.t option; [@default None] [@key "_links"]
        download_url : string option; [@default None]
        git_url : string option; [@default None]
        html_url : string option; [@default None]
        name : string option; [@default None]
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

  type t = {
    commit : Commit_.t;
    content : Content.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
