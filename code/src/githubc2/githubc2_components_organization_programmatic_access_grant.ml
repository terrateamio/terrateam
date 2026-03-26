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
      | `String "all" -> Ok `All
      | `String "none" -> Ok `None
      | `String "subset" -> Ok `Subset
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `All -> `String "all"
      | `None -> `String "none"
      | `Subset -> `String "subset"

    type t =
      ([ `All
       | `None
       | `Subset
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
    token_expires_at : string option; [@default None]
    token_id : int;
    token_last_used_at : string option; [@default None]
    token_name : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
