module Primary = struct
  module Aliases = struct
    module Items = struct
      module Primary = struct
        module Topic_relation = struct
          module Primary = struct
            type t = {
              id : int option; [@default None]
              name : string option; [@default None]
              relation_type : string option; [@default None]
              topic_id : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = { topic_relation : Topic_relation.t option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Related = struct
    module Items = struct
      module Primary = struct
        module Topic_relation = struct
          module Primary = struct
            type t = {
              id : int option; [@default None]
              name : string option; [@default None]
              relation_type : string option; [@default None]
              topic_id : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = { topic_relation : Topic_relation.t option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    aliases : Aliases.t option; [@default None]
    created_at : string;
    created_by : string option; [@default None]
    curated : bool;
    description : string option; [@default None]
    display_name : string option; [@default None]
    featured : bool;
    logo_url : string option; [@default None]
    name : string;
    related : Related.t option; [@default None]
    released : string option; [@default None]
    repository_count : int option; [@default None]
    score : float;
    short_description : string option; [@default None]
    text_matches : Githubc2_components_search_result_text_matches.t option; [@default None]
    updated_at : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
