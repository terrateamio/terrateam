module Primary = struct
  type t = {
    email : string option; [@default None]
    id : int;
    login : string;
    node_id : string option; [@default None]
    organization_billing_email : string option; [@default None]
    type_ : string; [@key "type"]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
