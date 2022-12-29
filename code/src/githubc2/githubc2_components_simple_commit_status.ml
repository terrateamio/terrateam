module Primary = struct
  type t = {
    avatar_url : string option;
    context : string;
    created_at : string;
    description : string option;
    id : int;
    node_id : string;
    required : bool option; [@default None]
    state : string;
    target_url : string option;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
