module Link = struct
  module Primary = struct
    type t = {
      markdown : string option; [@default None]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = {
  branch : string option; [@default None]
  file_name : string option; [@default None]
  file_path : string option; [@default None]
  link : Link.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
