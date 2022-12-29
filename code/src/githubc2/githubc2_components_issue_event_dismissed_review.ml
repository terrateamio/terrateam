module Primary = struct
  type t = {
    dismissal_commit_id : string option; [@default None]
    dismissal_message : string option;
    review_id : int;
    state : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
