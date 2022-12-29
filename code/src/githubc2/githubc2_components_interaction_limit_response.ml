module Primary = struct
  type t = {
    expires_at : string;
    limit : Githubc2_components_interaction_group.t;
    origin : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
