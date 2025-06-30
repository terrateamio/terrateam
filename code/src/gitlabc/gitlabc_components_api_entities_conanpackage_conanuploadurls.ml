module Primary = struct
  module Upload_urls = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  type t = { upload_urls : Upload_urls.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
