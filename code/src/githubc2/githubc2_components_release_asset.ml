module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "uploaded" -> Ok "uploaded"
      | `String "open" -> Ok "open"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    browser_download_url : string;
    content_type : string;
    created_at : string;
    download_count : int;
    id : int;
    label : string option;
    name : string;
    node_id : string;
    size : int;
    state : State.t;
    updated_at : string;
    uploader : Githubc2_components_nullable_simple_user.t option;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
