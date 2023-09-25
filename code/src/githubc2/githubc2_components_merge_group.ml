module Primary = struct
  type t = {
    base_ref : string;
    base_sha : string;
    head_commit : Githubc2_components_simple_commit.t;
    head_ref : string;
    head_sha : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
