module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "created" -> Ok "created"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    installation : Githubc2_components_simple_installation.t;
    organization : Githubc2_components_organization_simple_webhooks.t;
    personal_access_token_request : Githubc2_components_personal_access_token_request.t;
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)