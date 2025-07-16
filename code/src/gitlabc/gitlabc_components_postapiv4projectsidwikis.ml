module Format = struct
  let t_of_yojson = function
    | `String "markdown" -> Ok "markdown"
    | `String "rdoc" -> Ok "rdoc"
    | `String "asciidoc" -> Ok "asciidoc"
    | `String "org" -> Ok "org"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Front_matter = struct
  module Primary = struct
    type t = { title : string option [@default None] }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = {
  content : string;
  format : Format.t; [@default "markdown"]
  front_matter : Front_matter.t option; [@default None]
  title : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
