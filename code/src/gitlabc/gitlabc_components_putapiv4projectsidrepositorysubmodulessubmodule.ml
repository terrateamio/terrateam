module Primary = struct
  type t = {
    branch : string;
    commit_message : string option; [@default None]
    commit_sha : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
