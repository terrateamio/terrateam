module Format = struct
  let t_of_yojson = function
    | `String "asciidoc" -> Ok `Asciidoc
    | `String "markdown" -> Ok `Markdown
    | `String "org" -> Ok `Org
    | `String "rdoc" -> Ok `Rdoc
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Asciidoc -> `String "asciidoc"
    | `Markdown -> `String "markdown"
    | `Org -> `String "org"
    | `Rdoc -> `String "rdoc"

  type t =
    ([ `Asciidoc
     | `Markdown
     | `Org
     | `Rdoc
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
  format : Format.t; [@default `Markdown]
  front_matter : Front_matter.t option; [@default None]
  title : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
