module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "reopened_by_user" -> Ok `Reopened_by_user
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Reopened_by_user -> `String "reopened_by_user"

    type t = ([ `Reopened_by_user ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Alert = struct
    module Primary = struct
      module Dismissed_at = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Dismissed_by = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Dismissed_reason = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
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

          type t = {
            description : string;
            id : string;
            severity : Severity.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module State = struct
        let t_of_yojson = function
          | `String "fixed" -> Ok `Fixed
          | `String "open" -> Ok `Open
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        let t_to_yojson = function
          | `Fixed -> `String "fixed"
          | `Open -> `String "open"

        type t =
          ([ `Fixed
           | `Open
           ]
          [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Tool = struct
        module Primary = struct
          type t = {
            name : string;
            version : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        created_at : string;
        dismissed_at : Dismissed_at.t option; [@default None]
        dismissed_by : Dismissed_by.t option; [@default None]
        dismissed_comment : string option; [@default None]
        dismissed_reason : Dismissed_reason.t option; [@default None]
        fixed_at : Fixed_at.t option; [@default None]
        html_url : string;
        most_recent_instance : Most_recent_instance.t option; [@default None]
        number : int;
        rule : Rule.t;
        state : State.t option; [@default None]
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
