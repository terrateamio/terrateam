module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "moved" -> Ok "moved"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Changes = struct
    module Primary = struct
      module Column_id = struct
        module Primary = struct
          type t = { from : int } [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = { column_id : Column_id.t }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Project_card_ = struct
    module All_of = struct
      module Primary = struct
        module Creator = struct
          module Primary = struct
            module Type = struct
              let t_of_yojson = function
                | `String "Bot" -> Ok "Bot"
                | `String "User" -> Ok "User"
                | `String "Organization" -> Ok "Organization"
                | `String "Mannequin" -> Ok "Mannequin"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = {
              avatar_url : string option; [@default None]
              deleted : bool option; [@default None]
              email : string option; [@default None]
              events_url : string option; [@default None]
              followers_url : string option; [@default None]
              following_url : string option; [@default None]
              gists_url : string option; [@default None]
              gravatar_id : string option; [@default None]
              html_url : string option; [@default None]
              id : int;
              login : string;
              name : string option; [@default None]
              node_id : string option; [@default None]
              organizations_url : string option; [@default None]
              received_events_url : string option; [@default None]
              repos_url : string option; [@default None]
              site_admin : bool option; [@default None]
              starred_url : string option; [@default None]
              subscriptions_url : string option; [@default None]
              type_ : Type.t option; [@default None] [@key "type"]
              url : string option; [@default None]
              user_view_type : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          after_id : int option;
          archived : bool;
          column_id : int;
          column_url : string;
          content_url : string option; [@default None]
          created_at : string;
          creator : Creator.t option;
          id : int;
          node_id : string;
          note : string option;
          project_url : string;
          updated_at : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module T = struct
      module Primary = struct
        module Creator = struct
          module Primary = struct
            module Type = struct
              let t_of_yojson = function
                | `String "Bot" -> Ok "Bot"
                | `String "User" -> Ok "User"
                | `String "Organization" -> Ok "Organization"
                | `String "Mannequin" -> Ok "Mannequin"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            type t = {
              avatar_url : string option; [@default None]
              deleted : bool option; [@default None]
              email : string option; [@default None]
              events_url : string option; [@default None]
              followers_url : string option; [@default None]
              following_url : string option; [@default None]
              gists_url : string option; [@default None]
              gravatar_id : string option; [@default None]
              html_url : string option; [@default None]
              id : int;
              login : string;
              name : string option; [@default None]
              node_id : string option; [@default None]
              organizations_url : string option; [@default None]
              received_events_url : string option; [@default None]
              repos_url : string option; [@default None]
              site_admin : bool option; [@default None]
              starred_url : string option; [@default None]
              subscriptions_url : string option; [@default None]
              type_ : Type.t option; [@default None] [@key "type"]
              url : string option; [@default None]
              user_view_type : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          after_id : int option;
          archived : bool;
          column_id : int;
          column_url : string;
          content_url : string option; [@default None]
          created_at : string;
          creator : Creator.t option;
          id : int;
          node_id : string;
          note : string option;
          project_url : string;
          updated_at : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

    let of_yojson json =
      let open CCResult in
      flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
  end

  type t = {
    action : Action.t;
    changes : Changes.t option; [@default None]
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    project_card : Project_card_.t;
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
