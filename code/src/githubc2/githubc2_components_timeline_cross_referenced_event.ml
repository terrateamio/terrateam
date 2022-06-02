module Primary = struct
  module Source = struct
    module Primary = struct
      type t = {
        issue : Githubc2_components_issue.t option; [@default None]
        type_ : string option; [@default None] [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    actor : Githubc2_components_simple_user.t option; [@default None]
    created_at : string;
    event : string;
    source : Source.t;
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
