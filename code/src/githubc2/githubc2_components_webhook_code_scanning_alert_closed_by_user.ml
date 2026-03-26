module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "closed_by_user" -> Ok `Closed_by_user
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Closed_by_user -> `String "closed_by_user"

    type t = ([ `Closed_by_user ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Alert = struct
    module Primary = struct
      module Dismissal_approved_by = struct
        module Primary = struct
          module Type = struct
            let t_of_yojson = function
              | `String "Bot" -> Ok `Bot
              | `String "Organization" -> Ok `Organization
              | `String "User" -> Ok `User
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            let t_to_yojson = function
              | `Bot -> `String "Bot"
              | `Organization -> `String "Organization"
              | `User -> `String "User"

            type t =
              ([ `Bot
               | `Organization
               | `User
               ]
              [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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

      module Dismissed_by = struct
        module Primary = struct
          module Type = struct
            let t_of_yojson = function
              | `String "Bot" -> Ok `Bot
              | `String "Organization" -> Ok `Organization
              | `String "User" -> Ok `User
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            let t_to_yojson = function
              | `Bot -> `String "Bot"
              | `Organization -> `String "Organization"
              | `User -> `String "User"

            type t =
              ([ `Bot
               | `Organization
               | `User
               ]
              [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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

      module Dismissed_reason = struct
        let t_of_yojson = function
          | `String "false positive" -> Ok `False_positive
          | `String "used in tests" -> Ok `Used_in_tests
          | `String "won't fix" -> Ok `Won_t_fix
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `False_positive -> `String "false positive"
          | `Used_in_tests -> `String "used in tests"
          | `Won_t_fix -> `String "won't fix"

        type t =
          ([ `False_positive
           | `Used_in_tests
           | `Won_t_fix
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Fixed_at = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
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
              | `String "dismissed" -> Ok `Dismissed
              | `String "fixed" -> Ok `Fixed
              | `String "open" -> Ok `Open
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            let t_to_yojson = function
              | `Dismissed -> `String "dismissed"
              | `Fixed -> `String "fixed"
              | `Open -> `String "open"

            type t =
              ([ `Dismissed
               | `Fixed
               | `Open
               ]
              [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
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
              | `String "error" -> Ok `Error
              | `String "none" -> Ok `None
              | `String "note" -> Ok `Note
              | `String "warning" -> Ok `Warning
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            let t_to_yojson = function
              | `Error -> `String "error"
              | `None -> `String "none"
              | `Note -> `String "note"
              | `Warning -> `String "warning"

            type t =
              ([ `Error
               | `None
               | `Note
               | `Warning
               ]
              [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Tags = struct
            type t = string list option
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            description : string;
            full_description : string option; [@default None]
            help : string option; [@default None]
            help_uri : string option; [@default None]
            id : string;
            name : string option; [@default None]
            severity : Severity.t option; [@default None]
            tags : Tags.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module State = struct
        let t_of_yojson = function
          | `String "dismissed" -> Ok `Dismissed
          | `String "fixed" -> Ok `Fixed
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Dismissed -> `String "dismissed"
          | `Fixed -> `String "fixed"

        type t =
          ([ `Dismissed
           | `Fixed
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Tool = struct
        module Primary = struct
          type t = {
            guid : string option; [@default None]
            name : string;
            version : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        created_at : string;
        dismissal_approved_by : Dismissal_approved_by.t option; [@default None]
        dismissed_at : string;
        dismissed_by : Dismissed_by.t option; [@default None]
        dismissed_comment : string option; [@default None]
        dismissed_reason : Dismissed_reason.t option; [@default None]
        fixed_at : Fixed_at.t option; [@default None]
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
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
