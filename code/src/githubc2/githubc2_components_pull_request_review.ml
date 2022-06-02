module Primary = struct
  module Links_ = struct
    module Primary = struct
      module Html = struct
        module Primary = struct
          type t = { href : string } [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Pull_request_ = struct
        module Primary = struct
          type t = { href : string } [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        html : Html.t;
        pull_request : Pull_request_.t;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    links_ : Links_.t; [@key "_links"]
    author_association : Githubc2_components_author_association.t;
    body : string;
    body_html : string option; [@default None]
    body_text : string option; [@default None]
    commit_id : string;
    html_url : string;
    id : int;
    node_id : string;
    pull_request_url : string;
    state : string;
    submitted_at : string option; [@default None]
    user : Githubc2_components_nullable_simple_user.t option;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
