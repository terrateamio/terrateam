module Primary = struct
  type t = {
    archived : bool;
    id : int;
    name : string;
    organization : Githubc2_components_simple_classroom_organization.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
