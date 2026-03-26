module Primary = struct
  module Color = struct
    let t_of_yojson = function
      | `String "blue" -> Ok `Blue
      | `String "gray" -> Ok `Gray
      | `String "green" -> Ok `Green
      | `String "orange" -> Ok `Orange
      | `String "pink" -> Ok `Pink
      | `String "purple" -> Ok `Purple
      | `String "red" -> Ok `Red
      | `String "yellow" -> Ok `Yellow
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Blue -> `String "blue"
      | `Gray -> `String "gray"
      | `Green -> `String "green"
      | `Orange -> `String "orange"
      | `Pink -> `String "pink"
      | `Purple -> `String "purple"
      | `Red -> `String "red"
      | `Yellow -> `String "yellow"

    type t =
      ([ `Blue
       | `Gray
       | `Green
       | `Orange
       | `Pink
       | `Purple
       | `Red
       | `Yellow
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    color : Color.t option; [@default None]
    description : string option; [@default None]
    is_enabled : bool;
    name : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
