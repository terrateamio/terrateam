module Primary = struct
  module Commit_ = struct
    module Primary = struct
      module Tree = struct
        module Primary = struct
          type t = {
            sha : string;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        author : Githubc2_components_nullable_git_user.t option;
        comment_count : int;
        committer : Githubc2_components_nullable_git_user.t option;
        message : string;
        tree : Tree.t;
        url : string;
        verification : Githubc2_components_verification.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Files = struct
    module Items = struct
      module Primary = struct
        type t = {
          additions : int option; [@default None]
          blob_url : string option; [@default None]
          changes : int option; [@default None]
          contents_url : string option; [@default None]
          deletions : int option; [@default None]
          filename : string option; [@default None]
          patch : string option; [@default None]
          previous_filename : string option; [@default None]
          raw_url : string option; [@default None]
          sha : string option; [@default None]
          status : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Parents = struct
    module Items = struct
      module Primary = struct
        type t = {
          html_url : string option; [@default None]
          sha : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Stats = struct
    module Primary = struct
      type t = {
        additions : int option; [@default None]
        deletions : int option; [@default None]
        total : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    author : Githubc2_components_nullable_simple_user.t option;
    comments_url : string;
    commit : Commit_.t;
    committer : Githubc2_components_nullable_simple_user.t option;
    files : Files.t option; [@default None]
    html_url : string;
    node_id : string;
    parents : Parents.t;
    sha : string;
    stats : Stats.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
