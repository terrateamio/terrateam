module Primary = struct
  module Payload = struct
    module Primary = struct
      module Pages = struct
        module Items = struct
          module Primary = struct
            type t = {
              action : string option; [@default None]
              html_url : string option; [@default None]
              page_name : string option; [@default None]
              sha : string option; [@default None]
              summary : string option; [@default None]
              title : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        action : string option; [@default None]
        comment : Githubc2_components_issue_comment.t option; [@default None]
        issue : Githubc2_components_issue.t option; [@default None]
        pages : Pages.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Repo = struct
    module Primary = struct
      type t = {
        id : int;
        name : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    actor : Githubc2_components_actor.t;
    created_at : string option; [@default None]
    id : string;
    org : Githubc2_components_actor.t option; [@default None]
    payload : Payload.t;
    public : bool;
    repo : Repo.t;
    type_ : string option; [@default None] [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
