module Primary = struct
  module Permissions_added = struct
    module Primary = struct
      module Organization = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      module Other = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      module Repository_ = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      type t = {
        organization : Organization.t option; [@default None]
        other : Other.t option; [@default None]
        repository : Repository_.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Permissions_result = struct
    module Primary = struct
      module Organization = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      module Other = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      module Repository_ = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      type t = {
        organization : Organization.t option; [@default None]
        other : Other.t option; [@default None]
        repository : Repository_.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Permissions_upgraded = struct
    module Primary = struct
      module Organization = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      module Other = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      module Repository_ = struct
        module Additional = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
      end

      type t = {
        organization : Organization.t option; [@default None]
        other : Other.t option; [@default None]
        repository : Repository_.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Repositories = struct
    module Items = struct
      module Primary = struct
        type t = {
          full_name : string;
          id : int;
          name : string;
          node_id : string;
          private_ : bool; [@key "private"]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Repository_selection = struct
    let t_of_yojson = function
      | `String "none" -> Ok "none"
      | `String "all" -> Ok "all"
      | `String "subset" -> Ok "subset"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string;
    id : int;
    owner : Githubc2_components_simple_user.t;
    permissions_added : Permissions_added.t;
    permissions_result : Permissions_result.t;
    permissions_upgraded : Permissions_upgraded.t;
    repositories : Repositories.t option; [@default None]
    repository_count : int option; [@default None]
    repository_selection : Repository_selection.t;
    token_expired : bool;
    token_expires_at : string option; [@default None]
    token_id : int;
    token_last_used_at : string option; [@default None]
    token_name : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
