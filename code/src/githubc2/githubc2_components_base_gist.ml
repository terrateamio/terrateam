module Primary = struct
  module Files = struct
    module Additional = struct
      module Primary = struct
        type t = {
          filename : string option; [@default None]
          language : string option; [@default None]
          raw_url : string option; [@default None]
          size : int option; [@default None]
          type_ : string option; [@default None] [@key "type"]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
  end

  module Forks = struct
    module Items = struct
      type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module History = struct
    module Items = struct
      type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    comments : int;
    comments_url : string;
    commits_url : string;
    created_at : string;
    description : string option;
    files : Files.t;
    forks : Forks.t option; [@default None]
    forks_url : string;
    git_pull_url : string;
    git_push_url : string;
    history : History.t option; [@default None]
    html_url : string;
    id : string;
    node_id : string;
    owner : Githubc2_components_simple_user.t option; [@default None]
    public : bool;
    truncated : bool option; [@default None]
    updated_at : string;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
