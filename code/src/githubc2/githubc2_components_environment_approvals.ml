module Primary = struct
  module Environments = struct
    module Items = struct
      module Primary = struct
        type t = {
          created_at : string option; [@default None]
          html_url : string option; [@default None]
          id : int option; [@default None]
          name : string option; [@default None]
          node_id : string option; [@default None]
          updated_at : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module State = struct
    let t_of_yojson = function
      | `String "approved" -> Ok "approved"
      | `String "rejected" -> Ok "rejected"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    comment : string;
    environments : Environments.t;
    state : State.t;
    user : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
