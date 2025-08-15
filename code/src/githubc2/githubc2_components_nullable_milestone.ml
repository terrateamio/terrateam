module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "open" -> Ok "open"
      | `String "closed" -> Ok "closed"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    closed_at : string option; [@default None]
    closed_issues : int;
    created_at : string;
    creator : Githubc2_components_nullable_simple_user.t option; [@default None]
    description : string option; [@default None]
    due_on : string option; [@default None]
    html_url : string;
    id : int;
    labels_url : string;
    node_id : string;
    number : int;
    open_issues : int;
    state : State.t; [@default "open"]
    title : string;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
