module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "edited" -> Ok "edited"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Changes = struct
    module Primary = struct
      module Base = struct
        module Primary = struct
          module Ref = struct
            module Primary = struct
              type t = { from : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Sha = struct
            module Primary = struct
              type t = { from : string }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            ref_ : Ref.t; [@key "ref"]
            sha : Sha.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Body = struct
        module Primary = struct
          type t = { from : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Title = struct
        module Primary = struct
          type t = { from : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        base : Base.t option; [@default None]
        body : Body.t option; [@default None]
        title : Title.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    changes : Changes.t;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    number : int;
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    pull_request : Githubc2_components_pull_request_webhook.t;
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
