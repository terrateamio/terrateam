module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "appeared_in_branch" -> Ok "appeared_in_branch"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Alert = struct
    module Primary = struct
      module Dismissed_by = struct
        module Primary = struct
          module Type = struct
            let t_of_yojson = function
              | `String "Bot" -> Ok "Bot"
              | `String "User" -> Ok "User"
              | `String "Organization" -> Ok "Organization"
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
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Dismissed_reason = struct
        let t_of_yojson = function
          | `String "false positive" -> Ok "false positive"
          | `String "won't fix" -> Ok "won't fix"
          | `String "used in tests" -> Ok "used in tests"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Most_recent_instance = struct
        module Primary = struct
          module Classifications = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Location = struct
            module Primary = struct
              type t = {
                end_column : int option; [@default None]
                end_line : int option; [@default None]
                path : string option; [@default None]
                start_column : int option; [@default None]
                start_line : int option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Message = struct
            module Primary = struct
              type t = { text : string option [@default None] }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module State = struct
            let t_of_yojson = function
              | `String "open" -> Ok "open"
              | `String "dismissed" -> Ok "dismissed"
              | `String "fixed" -> Ok "fixed"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            analysis_key : string;
            category : string option; [@default None]
            classifications : Classifications.t option; [@default None]
            commit_sha : string option; [@default None]
            environment : string;
            location : Location.t option; [@default None]
            message : Message.t option; [@default None]
            ref_ : string; [@key "ref"]
            state : State.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Rule = struct
        module Primary = struct
          module Severity = struct
            let t_of_yojson = function
              | `String "none" -> Ok "none"
              | `String "note" -> Ok "note"
              | `String "warning" -> Ok "warning"
              | `String "error" -> Ok "error"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            description : string;
            id : string;
            severity : Severity.t option;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module State = struct
        let t_of_yojson = function
          | `String "open" -> Ok "open"
          | `String "dismissed" -> Ok "dismissed"
          | `String "fixed" -> Ok "fixed"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Tool = struct
        module Primary = struct
          type t = {
            name : string;
            version : string option;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        created_at : string;
        dismissed_at : string option;
        dismissed_by : Dismissed_by.t option;
        dismissed_reason : Dismissed_reason.t option;
        html_url : string;
        most_recent_instance : Most_recent_instance.t option; [@default None]
        number : int;
        rule : Rule.t;
        state : State.t;
        tool : Tool.t;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    alert : Alert.t;
    commit_oid : string;
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    ref_ : string; [@key "ref"]
    repository : Githubc2_components_repository_webhooks.t;
    sender : Githubc2_components_simple_user_webhooks.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
