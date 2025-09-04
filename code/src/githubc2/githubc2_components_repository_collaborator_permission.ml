module Primary = struct
  type t = {
    permission : string;
    role_name : string;
    user : Githubc2_components_nullable_collaborator.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
