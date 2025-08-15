module Primary = struct
  module Commit_ = struct
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

      type t = {
        author : Author.t;
        comment_count : int;
        committer : Githubc2_components_nullable_git_user.t option; [@default None]
        message : string;
        tree : Tree.t;
        url : string;
        verification : Githubc2_components_verification.t option; [@default None]
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

  type t = {
    author : Githubc2_components_nullable_simple_user.t option; [@default None]
    comments_url : string;
    commit : Commit_.t;
    committer : Githubc2_components_nullable_git_user.t option; [@default None]
    html_url : string;
    node_id : string;
    parents : Parents.t;
    repository : Githubc2_components_minimal_repository.t;
    score : float;
    sha : string;
    text_matches : Githubc2_components_search_result_text_matches.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
