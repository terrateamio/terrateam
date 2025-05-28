module Primary = struct
  module Permissions = struct
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
    access_granted_at : string;
    id : int;
    owner : Githubc2_components_simple_user.t;
    permissions : Permissions.t;
    repositories_url : string;
    repository_selection : Repository_selection.t;
    token_expired : bool;
    token_expires_at : string option;
    token_id : int;
    token_last_used_at : string option;
    token_name : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
