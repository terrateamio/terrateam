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
      module Body = struct
        module Primary = struct
          type t = {
            from : string option; [@default None]
            to_ : string option; [@default None] [@key "to"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Start_date = struct
        module Primary = struct
          type t = {
            from : string option; [@default None]
            to_ : string option; [@default None] [@key "to"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Status_ = struct
        module Primary = struct
          module From = struct
            let t_of_yojson = function
              | `String "INACTIVE" -> Ok "INACTIVE"
              | `String "ON_TRACK" -> Ok "ON_TRACK"
              | `String "AT_RISK" -> Ok "AT_RISK"
              | `String "OFF_TRACK" -> Ok "OFF_TRACK"
              | `String "COMPLETE" -> Ok "COMPLETE"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module To = struct
            let t_of_yojson = function
              | `String "INACTIVE" -> Ok "INACTIVE"
              | `String "ON_TRACK" -> Ok "ON_TRACK"
              | `String "AT_RISK" -> Ok "AT_RISK"
              | `String "OFF_TRACK" -> Ok "OFF_TRACK"
              | `String "COMPLETE" -> Ok "COMPLETE"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            from : From.t option; [@default None]
            to_ : To.t option; [@default None] [@key "to"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Target_date = struct
        module Primary = struct
          type t = {
            from : string option; [@default None]
            to_ : string option; [@default None] [@key "to"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        body : Body.t option; [@default None]
        start_date : Start_date.t option; [@default None]
        status : Status_.t option; [@default None]
        target_date : Target_date.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    changes : Changes.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t;
    projects_v2_status_update : Githubc2_components_projects_v2_status_update.t;
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
