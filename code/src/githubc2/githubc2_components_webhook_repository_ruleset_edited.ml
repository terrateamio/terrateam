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
      module Conditions = struct
        module Primary = struct
          module Added = struct
            type t = Githubc2_components_repository_ruleset_conditions.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Deleted = struct
            type t = Githubc2_components_repository_ruleset_conditions.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Updated = struct
            module Items = struct
              module Primary = struct
                module Changes = struct
                  module Primary = struct
                    module Condition_type = struct
                      module Primary = struct
                        type t = { from : string option [@default None] }
                        [@@deriving yojson { strict = false; meta = true }, show, eq]
                      end

                      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                    end

                    module Exclude = struct
                      module Primary = struct
                        module From = struct
                          type t = string list
                          [@@deriving yojson { strict = false; meta = true }, show, eq]
                        end

                        type t = { from : From.t option [@default None] }
                        [@@deriving yojson { strict = false; meta = true }, show, eq]
                      end

                      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                    end

                    module Include = struct
                      module Primary = struct
                        module From = struct
                          type t = string list
                          [@@deriving yojson { strict = false; meta = true }, show, eq]
                        end

                        type t = { from : From.t option [@default None] }
                        [@@deriving yojson { strict = false; meta = true }, show, eq]
                      end

                      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                    end

                    module Target = struct
                      module Primary = struct
                        type t = { from : string option [@default None] }
                        [@@deriving yojson { strict = false; meta = true }, show, eq]
                      end

                      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                    end

                    type t = {
                      condition_type : Condition_type.t option; [@default None]
                      exclude : Exclude.t option; [@default None]
                      include_ : Include.t option; [@default None] [@key "include"]
                      target : Target.t option; [@default None]
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                type t = {
                  changes : Changes.t option; [@default None]
                  condition : Githubc2_components_repository_ruleset_conditions.t option;
                      [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            added : Added.t option; [@default None]
            deleted : Deleted.t option; [@default None]
            updated : Updated.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Enforcement = struct
        module Primary = struct
          type t = { from : string option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Name = struct
        module Primary = struct
          type t = { from : string option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Rules = struct
        module Primary = struct
          module Added = struct
            type t = Githubc2_components_repository_rule.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Deleted = struct
            type t = Githubc2_components_repository_rule.t list
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Updated = struct
            module Items = struct
              module Primary = struct
                module Changes = struct
                  module Primary = struct
                    module Configuration = struct
                      module Primary = struct
                        type t = { from : string option [@default None] }
                        [@@deriving yojson { strict = false; meta = true }, show, eq]
                      end

                      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                    end

                    module Pattern = struct
                      module Primary = struct
                        type t = { from : string option [@default None] }
                        [@@deriving yojson { strict = false; meta = true }, show, eq]
                      end

                      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                    end

                    module Rule_type = struct
                      module Primary = struct
                        type t = { from : string option [@default None] }
                        [@@deriving yojson { strict = false; meta = true }, show, eq]
                      end

                      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                    end

                    type t = {
                      configuration : Configuration.t option; [@default None]
                      pattern : Pattern.t option; [@default None]
                      rule_type : Rule_type.t option; [@default None]
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                type t = {
                  changes : Changes.t option; [@default None]
                  rule : Githubc2_components_repository_rule.t option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            added : Added.t option; [@default None]
            deleted : Deleted.t option; [@default None]
            updated : Updated.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        conditions : Conditions.t option; [@default None]
        enforcement : Enforcement.t option; [@default None]
        name : Name.t option; [@default None]
        rules : Rules.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : Action.t;
    changes : Changes.t option; [@default None]
    enterprise : Githubc2_components_enterprise_webhooks.t option; [@default None]
    installation : Githubc2_components_simple_installation.t option; [@default None]
    organization : Githubc2_components_organization_simple_webhooks.t option; [@default None]
    repository : Githubc2_components_repository_webhooks.t option; [@default None]
    repository_ruleset : Githubc2_components_repository_ruleset.t;
    sender : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
