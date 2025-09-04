module Primary = struct
  module Action = struct
    let t_of_yojson = function
      | `String "created" -> Ok "created"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Alert = struct
    module Primary = struct
      module Dismissal_approved_by = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

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
          | `String "open" -> Ok "open"
          | `String "dismissed" -> Ok "dismissed"
          | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

        type t = (string[@of_yojson t_of_yojson])
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
        created_at : string option; [@default None]
        dismissal_approved_by : Dismissal_approved_by.t option; [@default None]
        dismissed_at : Dismissed_at.t option; [@default None]
        dismissed_by : Dismissed_by.t option; [@default None]
        dismissed_comment : string option; [@default None]
        dismissed_reason : Dismissed_reason.t option; [@default None]
        fixed_at : Fixed_at.t option; [@default None]
        html_url : string;
        instances_url : string option; [@default None]
        most_recent_instance : Most_recent_instance.t option; [@default None]
        number : int;
        rule : Rule.t;
        state : State.t option; [@default None]
        tool : Tool.t option; [@default None]
        updated_at : string option; [@default None]
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
