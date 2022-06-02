module Primary = struct
  module Subject = struct
    module Primary = struct
      type t = {
        latest_comment_url : string;
        title : string;
        type_ : string; [@key "type"]
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    id : string;
    last_read_at : string option;
    reason : string;
    repository : Githubc2_components_minimal_repository.t;
    subject : Subject.t;
    subscription_url : string;
    unread : bool;
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
