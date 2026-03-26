module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "open" -> Ok `Open
      | `String "uploaded" -> Ok `Uploaded
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Open -> `String "open"
      | `Uploaded -> `String "uploaded"

    type t =
      ([ `Open
       | `Uploaded
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    browser_download_url : string;
    content_type : string;
    created_at : string;
    download_count : int;
    id : int;
    label : string option; [@default None]
    name : string;
    node_id : string;
    size : int;
    state : State.t;
    updated_at : string;
    uploader : Githubc2_components_nullable_simple_user.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
