module Primary = struct
  type t = {
    expiry : Githubc2_components_interaction_expiry.t option; [@default None]
    limit : Githubc2_components_interaction_group.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
