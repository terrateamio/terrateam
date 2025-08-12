module Primary = struct
  module Author = struct
    type t =
      | Simple_user of Githubc2_components_simple_user.t
      | Empty_object of Githubc2_components_empty_object.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.any_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> Simple_user v) (Githubc2_components_simple_user.of_yojson v));
           (fun v -> map (fun v -> Empty_object v) (Githubc2_components_empty_object.of_yojson v));
         ])

    let to_yojson = function
      | Simple_user v -> Githubc2_components_simple_user.to_yojson v
      | Empty_object v -> Githubc2_components_empty_object.to_yojson v
  end

  module Commit_ = struct
    module Primary = struct
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
        author : Githubc2_components_nullable_git_user.t option;
        comment_count : int;
        committer : Githubc2_components_nullable_git_user.t option;
        message : string;
        tree : Tree.t;
        url : string;
        verification : Githubc2_components_verification.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Committer = struct
    type t =
      | Simple_user of Githubc2_components_simple_user.t
      | Empty_object of Githubc2_components_empty_object.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.any_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> Simple_user v) (Githubc2_components_simple_user.of_yojson v));
           (fun v -> map (fun v -> Empty_object v) (Githubc2_components_empty_object.of_yojson v));
         ])

    let to_yojson = function
      | Simple_user v -> Githubc2_components_simple_user.to_yojson v
      | Empty_object v -> Githubc2_components_empty_object.to_yojson v
  end

  module Files = struct
    type t = Githubc2_components_diff_entry.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Parents = struct
    module Items = struct
      module Primary = struct
        type t = {
          html_url : string option; [@default None]
          sha : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Stats = struct
    module Primary = struct
      type t = {
        additions : int option; [@default None]
        deletions : int option; [@default None]
        total : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    author : Author.t option;
    comments_url : string;
    commit : Commit_.t;
    committer : Committer.t option;
    files : Files.t option; [@default None]
    html_url : string;
    node_id : string;
    parents : Parents.t;
    sha : string;
    stats : Stats.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
