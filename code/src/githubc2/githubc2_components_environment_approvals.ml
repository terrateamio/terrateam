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
      | `String "approved" -> Ok `Approved
      | `String "pending" -> Ok `Pending
      | `String "rejected" -> Ok `Rejected
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Approved -> `String "approved"
      | `Pending -> `String "pending"
      | `Rejected -> `String "rejected"

    type t =
      ([ `Approved
       | `Pending
       | `Rejected
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
