module File_commit = struct
  module Primary = struct
    module Commit_ = struct
      module Primary = struct
        module Author = struct
          module Primary = struct
            type t = {
              date : string option; [@default None]
              email : string option; [@default None]
              name : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Committer = struct
          module Primary = struct
            type t = {
              date : string option; [@default None]
              email : string option; [@default None]
              name : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Parents = struct
          module Items = struct
            module Primary = struct
              type t = {
                html_url : string option; [@default None]
                sha : string option; [@default None]
                url : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
        end

        module Tree = struct
          module Primary = struct
            type t = {
              sha : string option; [@default None]
              url : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Verification_ = struct
          module Primary = struct
            type t = {
              payload : string option; [@default None]
              reason : string option; [@default None]
              signature : string option; [@default None]
              verified : bool option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          author : Author.t option; [@default None]
          committer : Committer.t option; [@default None]
          html_url : string option; [@default None]
          message : string option; [@default None]
          node_id : string option; [@default None]
          parents : Parents.t option; [@default None]
          sha : string option; [@default None]
          tree : Tree.t option; [@default None]
          url : string option; [@default None]
          verification : Verification_.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Content = struct
      module Primary = struct
        module Links_ = struct
          module Primary = struct
            type t = {
              git : string option; [@default None]
              html : string option; [@default None]
              self : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          links_ : Links_.t option; [@default None] [@key "_links"]
          download_url : string option; [@default None]
          git_url : string option; [@default None]
          html_url : string option; [@default None]
          name : string option; [@default None]
          path : string option; [@default None]
          sha : string option; [@default None]
          size : int option; [@default None]
          type_ : string option; [@default None] [@key "type"]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      commit : Commit_.t;
      content : Content.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Collaborator = struct
  module Primary = struct
    module Permissions = struct
      module Primary = struct
        type t = {
          admin : bool;
          maintain : bool option; [@default None]
          pull : bool;
          push : bool;
          triage : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      avatar_url : string;
      email : string option; [@default None]
      events_url : string;
      followers_url : string;
      following_url : string;
      gists_url : string;
      gravatar_id : string option;
      html_url : string;
      id : int;
      login : string;
      name : string option; [@default None]
      node_id : string;
      organizations_url : string;
      permissions : Permissions.t option; [@default None]
      received_events_url : string;
      repos_url : string;
      site_admin : bool;
      starred_url : string;
      subscriptions_url : string;
      type_ : string; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Branch_restriction_policy = struct
  module Primary = struct
    module Apps = struct
      module Items = struct
        module Primary = struct
          module Events = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show]
          end

          module Owner = struct
            module Primary = struct
              type t = {
                avatar_url : string option; [@default None]
                description : string option; [@default None]
                events_url : string option; [@default None]
                followers_url : string option; [@default None]
                following_url : string option; [@default None]
                gists_url : string option; [@default None]
                gravatar_id : string option; [@default None]
                hooks_url : string option; [@default None]
                html_url : string option; [@default None]
                id : int option; [@default None]
                issues_url : string option; [@default None]
                login : string option; [@default None]
                members_url : string option; [@default None]
                node_id : string option; [@default None]
                organizations_url : string option; [@default None]
                public_members_url : string option; [@default None]
                received_events_url : string option; [@default None]
                repos_url : string option; [@default None]
                site_admin : bool option; [@default None]
                starred_url : string option; [@default None]
                subscriptions_url : string option; [@default None]
                type_ : string option; [@default None] [@key "type"]
                url : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Permissions = struct
            module Primary = struct
              type t = {
                contents : string option; [@default None]
                issues : string option; [@default None]
                metadata : string option; [@default None]
                single_file : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            created_at : string option; [@default None]
            description : string option; [@default None]
            events : Events.t option; [@default None]
            external_url : string option; [@default None]
            html_url : string option; [@default None]
            id : int option; [@default None]
            name : string option; [@default None]
            node_id : string option; [@default None]
            owner : Owner.t option; [@default None]
            permissions : Permissions.t option; [@default None]
            slug : string option; [@default None]
            updated_at : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Teams = struct
      module Items = struct
        module Primary = struct
          type t = {
            description : string option; [@default None]
            html_url : string option; [@default None]
            id : int option; [@default None]
            members_url : string option; [@default None]
            name : string option; [@default None]
            node_id : string option; [@default None]
            parent : string option; [@default None]
            permission : string option; [@default None]
            privacy : string option; [@default None]
            repositories_url : string option; [@default None]
            slug : string option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Users = struct
      module Items = struct
        module Primary = struct
          type t = {
            avatar_url : string option; [@default None]
            events_url : string option; [@default None]
            followers_url : string option; [@default None]
            following_url : string option; [@default None]
            gists_url : string option; [@default None]
            gravatar_id : string option; [@default None]
            html_url : string option; [@default None]
            id : int option; [@default None]
            login : string option; [@default None]
            node_id : string option; [@default None]
            organizations_url : string option; [@default None]
            received_events_url : string option; [@default None]
            repos_url : string option; [@default None]
            site_admin : bool option; [@default None]
            starred_url : string option; [@default None]
            subscriptions_url : string option; [@default None]
            type_ : string option; [@default None] [@key "type"]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      apps : Apps.t;
      apps_url : string;
      teams : Teams.t;
      teams_url : string;
      url : string;
      users : Users.t;
      users_url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Alert_created_at = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Rate_limit = struct
  module Primary = struct
    type t = {
      limit : int;
      remaining : int;
      reset : int;
      used : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Pages_https_certificate = struct
  module Primary = struct
    module Domains = struct
      module Items = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module State = struct
      let t_of_yojson = function
        | `String "new" -> Ok "new"
        | `String "authorization_created" -> Ok "authorization_created"
        | `String "authorization_pending" -> Ok "authorization_pending"
        | `String "authorized" -> Ok "authorized"
        | `String "authorization_revoked" -> Ok "authorization_revoked"
        | `String "issued" -> Ok "issued"
        | `String "uploaded" -> Ok "uploaded"
        | `String "approved" -> Ok "approved"
        | `String "errored" -> Ok "errored"
        | `String "bad_authz" -> Ok "bad_authz"
        | `String "destroy_pending" -> Ok "destroy_pending"
        | `String "dns_changed" -> Ok "dns_changed"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      description : string;
      domains : Domains.t;
      expires_at : string option; [@default None]
      state : State.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Contributor = struct
  module Primary = struct
    type t = {
      avatar_url : string option; [@default None]
      contributions : int;
      email : string option; [@default None]
      events_url : string option; [@default None]
      followers_url : string option; [@default None]
      following_url : string option; [@default None]
      gists_url : string option; [@default None]
      gravatar_id : string option; [@default None]
      html_url : string option; [@default None]
      id : int option; [@default None]
      login : string option; [@default None]
      name : string option; [@default None]
      node_id : string option; [@default None]
      organizations_url : string option; [@default None]
      received_events_url : string option; [@default None]
      repos_url : string option; [@default None]
      site_admin : bool option; [@default None]
      starred_url : string option; [@default None]
      subscriptions_url : string option; [@default None]
      type_ : string; [@key "type"]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_alert_state = struct
  let t_of_yojson = function
    | `String "open" -> Ok "open"
    | `String "closed" -> Ok "closed"
    | `String "dismissed" -> Ok "dismissed"
    | `String "fixed" -> Ok "fixed"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Wait_timer = struct
  type t = int [@@deriving yojson { strict = false; meta = true }, show]
end

module Webhook_config_content_type = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Code_scanning_alert_environment = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Combined_billing_usage = struct
  module Primary = struct
    type t = {
      days_left_in_billing_cycle : int;
      estimated_paid_storage_for_month : int;
      estimated_storage_for_month : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Alert_url = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Deployment_reviewer_type = struct
  let t_of_yojson = function
    | `String "User" -> Ok "User"
    | `String "Team" -> Ok "Team"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Code_scanning_analysis_deletion = struct
  module Primary = struct
    type t = {
      confirm_delete_url : string option;
      next_analysis_url : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Reaction_rollup = struct
  module Primary = struct
    type t = {
      plus_one : int; [@key "+1"]
      minus_one : int; [@key "-1"]
      confused : int;
      eyes : int;
      heart : int;
      hooray : int;
      laugh : int;
      rocket : int;
      total_count : int;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Marketplace_account = struct
  module Primary = struct
    type t = {
      email : string option; [@default None]
      id : int;
      login : string;
      node_id : string option; [@default None]
      organization_billing_email : string option; [@default None]
      type_ : string; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis_url = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Issue_event_label = struct
  module Primary = struct
    type t = {
      color : string option;
      name : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis_created_at = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Verification = struct
  module Primary = struct
    type t = {
      payload : string option;
      reason : string;
      signature : string option;
      verified : bool;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Allowed_actions = struct
  let t_of_yojson = function
    | `String "all" -> Ok "all"
    | `String "local_only" -> Ok "local_only"
    | `String "selected" -> Ok "selected"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Gpg_key = struct
  module Primary = struct
    module Emails = struct
      module Items = struct
        module Primary = struct
          type t = {
            email : string option; [@default None]
            verified : bool option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Subkeys = struct
      module Items = struct
        module Primary = struct
          module Emails = struct
            module Items = struct
              type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
          end

          module Subkeys = struct
            module Items = struct
              type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = {
            can_certify : bool option; [@default None]
            can_encrypt_comms : bool option; [@default None]
            can_encrypt_storage : bool option; [@default None]
            can_sign : bool option; [@default None]
            created_at : string option; [@default None]
            emails : Emails.t option; [@default None]
            expires_at : string option; [@default None]
            id : int option; [@default None]
            key_id : string option; [@default None]
            primary_key_id : int option; [@default None]
            public_key : string option; [@default None]
            raw_key : string option; [@default None]
            subkeys : Subkeys.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      can_certify : bool;
      can_encrypt_comms : bool;
      can_encrypt_storage : bool;
      can_sign : bool;
      created_at : string;
      emails : Emails.t;
      expires_at : string option;
      id : int;
      key_id : string;
      primary_key_id : int option;
      public_key : string;
      raw_key : string option;
      subkeys : Subkeys.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module License_simple = struct
  module Primary = struct
    type t = {
      html_url : string option; [@default None]
      key : string;
      name : string;
      node_id : string;
      spdx_id : string option;
      url : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Webhook_config_insecure_ssl = struct
  module V0 = struct
    type t = string [@@deriving yojson { strict = false; meta = true }, show]
  end

  module V1 = struct
    type t = float [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t =
    | V0 of V0.t
    | V1 of V1.t
  [@@deriving show]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
      [
        (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
        (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
      ])

  let to_yojson = function
    | V0 v -> V0.to_yojson v
    | V1 v -> V1.to_yojson v
end

module Code_scanning_alert_location = struct
  module Primary = struct
    type t = {
      end_column : int option; [@default None]
      end_line : int option; [@default None]
      path : string option; [@default None]
      start_column : int option; [@default None]
      start_line : int option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Merged_upstream = struct
  module Primary = struct
    module Merge_type = struct
      let t_of_yojson = function
        | `String "merge" -> Ok "merge"
        | `String "fast-forward" -> Ok "fast-forward"
        | `String "none" -> Ok "none"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      base_branch : string option; [@default None]
      merge_type : Merge_type.t option; [@default None]
      message : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis_tool_name = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Code_scanning_alert_rule_summary = struct
  module Primary = struct
    module Severity = struct
      let t_of_yojson = function
        | `String "none" -> Ok "none"
        | `String "note" -> Ok "note"
        | `String "warning" -> Ok "warning"
        | `String "error" -> Ok "error"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      description : string option; [@default None]
      id : string option; [@default None]
      name : string option; [@default None]
      severity : Severity.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Actions_billing_usage = struct
  module Primary = struct
    module Minutes_used_breakdown = struct
      module Primary = struct
        type t = {
          macos : int option; [@default None] [@key "MACOS"]
          ubuntu : int option; [@default None] [@key "UBUNTU"]
          windows : int option; [@default None] [@key "WINDOWS"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      included_minutes : int;
      minutes_used_breakdown : Minutes_used_breakdown.t;
      total_minutes_used : int;
      total_paid_minutes_used : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Page_build_status = struct
  module Primary = struct
    type t = {
      status : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Hook_delivery_item = struct
  module Primary = struct
    type t = {
      action : string option;
      delivered_at : string;
      duration : float;
      event : string;
      guid : string;
      id : int;
      installation_id : int option;
      redelivery : bool;
      repository_id : int option;
      status : string;
      status_code : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Diff_entry = struct
  module Primary = struct
    module Status_ = struct
      let t_of_yojson = function
        | `String "added" -> Ok "added"
        | `String "removed" -> Ok "removed"
        | `String "modified" -> Ok "modified"
        | `String "renamed" -> Ok "renamed"
        | `String "copied" -> Ok "copied"
        | `String "changed" -> Ok "changed"
        | `String "unchanged" -> Ok "unchanged"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      additions : int;
      blob_url : string;
      changes : int;
      contents_url : string;
      deletions : int;
      filename : string;
      patch : string option; [@default None]
      previous_filename : string option; [@default None]
      raw_url : string;
      sha : string;
      status : Status_.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Validation_error = struct
  module Primary = struct
    module Errors = struct
      module Items = struct
        module Primary = struct
          module Value = struct
            module V0 = struct
              type t = string option [@@deriving yojson { strict = false; meta = true }, show]
            end

            module V1 = struct
              type t = int option [@@deriving yojson { strict = false; meta = true }, show]
            end

            module V2 = struct
              type t = string list option [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t =
              | V0 of V0.t
              | V1 of V1.t
              | V2 of V2.t
            [@@deriving show]

            let of_yojson =
              Json_schema.one_of
                (let open CCResult in
                [
                  (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                  (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                  (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
                ])

            let to_yojson = function
              | V0 v -> V0.to_yojson v
              | V1 v -> V1.to_yojson v
              | V2 v -> V2.to_yojson v
          end

          type t = {
            code : string;
            field : string option; [@default None]
            index : int option; [@default None]
            message : string option; [@default None]
            resource : string option; [@default None]
            value : Value.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      documentation_url : string;
      errors : Errors.t option; [@default None]
      message : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Scim_enterprise_user = struct
  module Primary = struct
    module Emails = struct
      module Items = struct
        module Primary = struct
          type t = {
            primary : bool option; [@default None]
            type_ : string option; [@default None] [@key "type"]
            value : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Groups = struct
      module Items = struct
        module Primary = struct
          type t = { value : string option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Meta = struct
      module Primary = struct
        type t = {
          created : string option; [@default None]
          lastmodified : string option; [@default None] [@key "lastModified"]
          location : string option; [@default None]
          resourcetype : string option; [@default None] [@key "resourceType"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Name = struct
      module Primary = struct
        type t = {
          familyname : string option; [@default None] [@key "familyName"]
          givenname : string option; [@default None] [@key "givenName"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Schemas = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      active : bool option; [@default None]
      emails : Emails.t option; [@default None]
      externalid : string option; [@default None] [@key "externalId"]
      groups : Groups.t option; [@default None]
      id : string;
      meta : Meta.t option; [@default None]
      name : Name.t option; [@default None]
      schemas : Schemas.t;
      username : string option; [@default None] [@key "userName"]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Gitignore_template = struct
  module Primary = struct
    type t = {
      name : string;
      source : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Content_reference_attachment = struct
  module Primary = struct
    type t = {
      body : string;
      id : int;
      node_id : string option; [@default None]
      title : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Nullable_community_health_file = struct
  module Primary = struct
    type t = {
      html_url : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis_tool_version = struct
  type t = string option [@@deriving yojson { strict = false; meta = true }, show]
end

module Interaction_group = struct
  let t_of_yojson = function
    | `String "existing_users" -> Ok "existing_users"
    | `String "contributors_only" -> Ok "contributors_only"
    | `String "collaborators_only" -> Ok "collaborators_only"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Nullable_simple_user = struct
  module Primary = struct
    type t = {
      avatar_url : string;
      email : string option; [@default None]
      events_url : string;
      followers_url : string;
      following_url : string;
      gists_url : string;
      gravatar_id : string option;
      html_url : string;
      id : int;
      login : string;
      name : string option; [@default None]
      node_id : string;
      organizations_url : string;
      received_events_url : string;
      repos_url : string;
      site_admin : bool;
      starred_at : string option; [@default None]
      starred_url : string;
      subscriptions_url : string;
      type_ : string; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Hook_delivery = struct
  module Primary = struct
    module Request = struct
      module Primary = struct
        module Headers = struct
          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
        end

        module Payload = struct
          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
        end

        type t = {
          headers : Headers.t option;
          payload : Payload.t option;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Response = struct
      module Primary = struct
        module Headers = struct
          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
        end

        type t = {
          headers : Headers.t option;
          payload : string option;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      action : string option;
      delivered_at : string;
      duration : float;
      event : string;
      guid : string;
      id : int;
      installation_id : int option;
      redelivery : bool;
      repository_id : int option;
      request : Request.t;
      response : Response.t;
      status : string;
      status_code : int;
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Simple_commit = struct
  module Primary = struct
    module Author = struct
      module Primary = struct
        type t = {
          email : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Committer = struct
      module Primary = struct
        type t = {
          email : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      author : Author.t option;
      committer : Committer.t option;
      id : string;
      message : string;
      timestamp : string;
      tree_id : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis_sarif_id = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Webhook_config_secret = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Package_version = struct
  module Primary = struct
    module Metadata = struct
      module Primary = struct
        module Container = struct
          module Primary = struct
            module Tags = struct
              module Items = struct
                type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
              end

              type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = { tags : Tags.t } [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Docker = struct
          module Primary = struct
            module Tag_ = struct
              module Items = struct
                type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
              end

              type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = { tag : Tag_.t option [@default None] }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Package_type = struct
          let t_of_yojson = function
            | `String "npm" -> Ok "npm"
            | `String "maven" -> Ok "maven"
            | `String "rubygems" -> Ok "rubygems"
            | `String "docker" -> Ok "docker"
            | `String "nuget" -> Ok "nuget"
            | `String "container" -> Ok "container"
            | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

          type t = (string[@of_yojson t_of_yojson])
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          container : Container.t option; [@default None]
          docker : Docker.t option; [@default None]
          package_type : Package_type.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      created_at : string;
      deleted_at : string option; [@default None]
      description : string option; [@default None]
      html_url : string option; [@default None]
      id : int;
      license : string option; [@default None]
      metadata : Metadata.t option; [@default None]
      name : string;
      package_html_url : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Repository_subscription = struct
  module Primary = struct
    type t = {
      created_at : string;
      ignored : bool;
      reason : string option;
      repository_url : string;
      subscribed : bool;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Actor = struct
  module Primary = struct
    type t = {
      avatar_url : string;
      display_login : string option; [@default None]
      gravatar_id : string option;
      id : int;
      login : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Key = struct
  module Primary = struct
    type t = {
      created_at : string;
      id : int;
      key : string;
      read_only : bool;
      title : string;
      url : string;
      verified : bool;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Content_directory = struct
  module Items = struct
    module Primary = struct
      module Links_ = struct
        module Primary = struct
          type t = {
            git : string option;
            html : string option;
            self : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        links_ : Links_.t; [@key "_links"]
        content : string option; [@default None]
        download_url : string option;
        git_url : string option;
        html_url : string option;
        name : string;
        path : string;
        sha : string;
        size : int;
        type_ : string; [@key "type"]
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

module Git_ref = struct
  module Primary = struct
    module Object = struct
      module Primary = struct
        type t = {
          sha : string;
          type_ : string; [@key "type"]
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      node_id : string;
      object_ : Object.t; [@key "object"]
      ref_ : string; [@key "ref"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Nullable_code_of_conduct_simple = struct
  module Primary = struct
    type t = {
      html_url : string option;
      key : string;
      name : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Scim_user_list_enterprise = struct
  module Primary = struct
    module Resources = struct
      module Items = struct
        module Primary = struct
          module Emails = struct
            module Items = struct
              module Primary = struct
                type t = {
                  primary : bool option; [@default None]
                  type_ : string option; [@default None] [@key "type"]
                  value : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
          end

          module Groups = struct
            module Items = struct
              module Primary = struct
                type t = { value : string option [@default None] }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
          end

          module Meta = struct
            module Primary = struct
              type t = {
                created : string option; [@default None]
                lastmodified : string option; [@default None] [@key "lastModified"]
                location : string option; [@default None]
                resourcetype : string option; [@default None] [@key "resourceType"]
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Name = struct
            module Primary = struct
              type t = {
                familyname : string option; [@default None] [@key "familyName"]
                givenname : string option; [@default None] [@key "givenName"]
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Schemas = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = {
            active : bool option; [@default None]
            emails : Emails.t option; [@default None]
            externalid : string option; [@default None] [@key "externalId"]
            groups : Groups.t option; [@default None]
            id : string;
            meta : Meta.t option; [@default None]
            name : Name.t option; [@default None]
            schemas : Schemas.t;
            username : string option; [@default None] [@key "userName"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Schemas = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      resources : Resources.t; [@key "Resources"]
      itemsperpage : float; [@key "itemsPerPage"]
      schemas : Schemas.t;
      startindex : float; [@key "startIndex"]
      totalresults : float; [@key "totalResults"]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_alert_dismissed_at = struct
  type t = string option [@@deriving yojson { strict = false; meta = true }, show]
end

module Job = struct
  module Primary = struct
    module Labels = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Status_ = struct
      let t_of_yojson = function
        | `String "queued" -> Ok "queued"
        | `String "in_progress" -> Ok "in_progress"
        | `String "completed" -> Ok "completed"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Steps = struct
      module Items = struct
        module Primary = struct
          module Status_ = struct
            let t_of_yojson = function
              | `String "queued" -> Ok "queued"
              | `String "in_progress" -> Ok "in_progress"
              | `String "completed" -> Ok "completed"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = {
            completed_at : string option; [@default None]
            conclusion : string option;
            name : string;
            number : int;
            started_at : string option; [@default None]
            status : Status_.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      check_run_url : string;
      completed_at : string option;
      conclusion : string option;
      head_sha : string;
      html_url : string option;
      id : int;
      labels : Labels.t;
      name : string;
      node_id : string;
      run_attempt : int option; [@default None]
      run_id : int;
      run_url : string;
      runner_group_id : int option;
      runner_group_name : string option;
      runner_id : int option;
      runner_name : string option;
      started_at : string;
      status : Status_.t;
      steps : Steps.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_alert_rule = struct
  module Primary = struct
    module Security_severity_level = struct
      let t_of_yojson = function
        | `String "low" -> Ok "low"
        | `String "medium" -> Ok "medium"
        | `String "high" -> Ok "high"
        | `String "critical" -> Ok "critical"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Severity = struct
      let t_of_yojson = function
        | `String "none" -> Ok "none"
        | `String "note" -> Ok "note"
        | `String "warning" -> Ok "warning"
        | `String "error" -> Ok "error"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Tags = struct
      type t = string list option [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      description : string option; [@default None]
      full_description : string option; [@default None]
      help : string option; [@default None]
      id : string option; [@default None]
      name : string option; [@default None]
      security_severity_level : Security_severity_level.t option; [@default None]
      severity : Severity.t option; [@default None]
      tags : Tags.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Public_user = struct
  module Plan = struct
    module Primary = struct
      type t = {
        collaborators : int;
        name : string;
        private_repos : int;
        space : int;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    avatar_url : string;
    bio : string option;
    blog : string option;
    collaborators : int option; [@default None]
    company : string option;
    created_at : string;
    disk_usage : int option; [@default None]
    email : string option;
    events_url : string;
    followers : int;
    followers_url : string;
    following : int;
    following_url : string;
    gists_url : string;
    gravatar_id : string option;
    hireable : bool option;
    html_url : string;
    id : int;
    location : string option;
    login : string;
    name : string option;
    node_id : string;
    organizations_url : string;
    owned_private_repos : int option; [@default None]
    plan : Plan.t option; [@default None]
    private_gists : int option; [@default None]
    public_gists : int;
    public_repos : int;
    received_events_url : string;
    repos_url : string;
    site_admin : bool;
    starred_url : string;
    subscriptions_url : string;
    suspended_at : string option; [@default None]
    total_private_repos : int option; [@default None]
    twitter_username : string option; [@default None]
    type_ : string; [@key "type"]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = true; meta = true }, show]
end

module Nullable_team_simple = struct
  module Primary = struct
    type t = {
      description : string option;
      html_url : string;
      id : int;
      ldap_dn : string option; [@default None]
      members_url : string;
      name : string;
      node_id : string;
      permission : string;
      privacy : string option; [@default None]
      repositories_url : string;
      slug : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_frequency_stat = struct
  type t = int list [@@deriving yojson { strict = false; meta = true }, show]
end

module Hovercard = struct
  module Primary = struct
    module Contexts = struct
      module Items = struct
        module Primary = struct
          type t = {
            message : string;
            octicon : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = { contexts : Contexts.t } [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Secret_scanning_alert_resolution = struct
  let t_of_yojson = function
    | `String "false_positive" -> Ok "false_positive"
    | `String "wont_fix" -> Ok "wont_fix"
    | `String "revoked" -> Ok "revoked"
    | `String "used_in_tests" -> Ok "used_in_tests"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson]) option
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Organization_full = struct
  module Primary = struct
    module Plan = struct
      module Primary = struct
        type t = {
          filled_seats : int option; [@default None]
          name : string;
          private_repos : int;
          seats : int option; [@default None]
          space : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      avatar_url : string;
      billing_email : string option; [@default None]
      blog : string option; [@default None]
      collaborators : int option; [@default None]
      company : string option; [@default None]
      created_at : string;
      default_repository_permission : string option; [@default None]
      description : string option;
      disk_usage : int option; [@default None]
      email : string option; [@default None]
      events_url : string;
      followers : int;
      following : int;
      has_organization_projects : bool;
      has_repository_projects : bool;
      hooks_url : string;
      html_url : string;
      id : int;
      is_verified : bool option; [@default None]
      issues_url : string;
      location : string option; [@default None]
      login : string;
      members_allowed_repository_creation_type : string option; [@default None]
      members_can_create_internal_repositories : bool option; [@default None]
      members_can_create_pages : bool option; [@default None]
      members_can_create_private_pages : bool option; [@default None]
      members_can_create_private_repositories : bool option; [@default None]
      members_can_create_public_pages : bool option; [@default None]
      members_can_create_public_repositories : bool option; [@default None]
      members_can_create_repositories : bool option; [@default None]
      members_url : string;
      name : string option; [@default None]
      node_id : string;
      owned_private_repos : int option; [@default None]
      plan : Plan.t option; [@default None]
      private_gists : int option; [@default None]
      public_gists : int;
      public_members_url : string;
      public_repos : int;
      repos_url : string;
      total_private_repos : int option; [@default None]
      twitter_username : string option; [@default None]
      two_factor_requirement_enabled : bool option; [@default None]
      type_ : string; [@key "type"]
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Nullable_license_simple = struct
  module Primary = struct
    type t = {
      html_url : string option; [@default None]
      key : string;
      name : string;
      node_id : string;
      spdx_id : string option;
      url : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Hook_response = struct
  module Primary = struct
    type t = {
      code : int option;
      message : string option;
      status : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Commit_activity = struct
  module Primary = struct
    module Days = struct
      type t = int list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      days : Days.t;
      total : int;
      week : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Content_submodule = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          git : string option;
          html : string option;
          self : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      download_url : string option;
      git_url : string option;
      html_url : string option;
      name : string;
      path : string;
      sha : string;
      size : int;
      submodule_git_url : string;
      type_ : string; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Team_membership = struct
  module Primary = struct
    module Role = struct
      let t_of_yojson = function
        | `String "member" -> Ok "member"
        | `String "maintainer" -> Ok "maintainer"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module State = struct
      let t_of_yojson = function
        | `String "active" -> Ok "active"
        | `String "pending" -> Ok "pending"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      role : Role.t; [@default "member"]
      state : State.t;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Referrer_traffic = struct
  module Primary = struct
    type t = {
      count : int;
      referrer : string;
      uniques : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_alert_classification = struct
  let t_of_yojson = function
    | `String "source" -> Ok "source"
    | `String "generated" -> Ok "generated"
    | `String "test" -> Ok "test"
    | `String "library" -> Ok "library"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson]) option
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Pull_request_merge_result = struct
  module Primary = struct
    type t = {
      merged : bool;
      message : string;
      sha : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Link_with_type = struct
  module Primary = struct
    type t = {
      href : string;
      type_ : string; [@key "type"]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Label = struct
  module Primary = struct
    type t = {
      color : string;
      default : bool;
      description : string option;
      id : int64;
      name : string;
      node_id : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Scim_user = struct
  module Primary = struct
    module Emails = struct
      module Items = struct
        module Primary = struct
          type t = {
            primary : bool option; [@default None]
            value : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Groups = struct
      module Items = struct
        module Primary = struct
          type t = {
            display : string option; [@default None]
            value : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Meta = struct
      module Primary = struct
        type t = {
          created : string option; [@default None]
          lastmodified : string option; [@default None] [@key "lastModified"]
          location : string option; [@default None]
          resourcetype : string option; [@default None] [@key "resourceType"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Name = struct
      module Primary = struct
        type t = {
          familyname : string option; [@key "familyName"]
          formatted : string option; [@default None]
          givenname : string option; [@key "givenName"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Operations = struct
      module Items = struct
        module Primary = struct
          module Op = struct
            let t_of_yojson = function
              | `String "add" -> Ok "add"
              | `String "remove" -> Ok "remove"
              | `String "replace" -> Ok "replace"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          module Value = struct
            module V0 = struct
              type t = string [@@deriving yojson { strict = false; meta = true }, show]
            end

            module V1 = struct
              include
                Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
            end

            module V2 = struct
              module Items = struct
                type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
              end

              type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t =
              | V0 of V0.t
              | V1 of V1.t
              | V2 of V2.t
            [@@deriving show]

            let of_yojson =
              Json_schema.one_of
                (let open CCResult in
                [
                  (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
                  (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
                  (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
                ])

            let to_yojson = function
              | V0 v -> V0.to_yojson v
              | V1 v -> V1.to_yojson v
              | V2 v -> V2.to_yojson v
          end

          type t = {
            op : Op.t;
            path : string option; [@default None]
            value : Value.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Schemas = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      active : bool;
      displayname : string option; [@default None] [@key "displayName"]
      emails : Emails.t;
      externalid : string option; [@key "externalId"]
      groups : Groups.t option; [@default None]
      id : string;
      meta : Meta.t;
      name : Name.t;
      operations : Operations.t option; [@default None]
      organization_id : int option; [@default None]
      schemas : Schemas.t;
      username : string option; [@key "userName"]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis_tool_guid = struct
  type t = string option [@@deriving yojson { strict = false; meta = true }, show]
end

module Short_blob = struct
  module Primary = struct
    type t = {
      sha : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Branch_short = struct
  module Primary = struct
    module Commit_ = struct
      module Primary = struct
        type t = {
          sha : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      commit : Commit_.t;
      name : string;
      protected : bool;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Selected_actions = struct
  module Primary = struct
    module Patterns_allowed = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      github_owned_allowed : bool option; [@default None]
      patterns_allowed : Patterns_allowed.t option; [@default None]
      verified_allowed : bool option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Protected_branch_admin_enforced = struct
  module Primary = struct
    type t = {
      enabled : bool;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Enabled_repositories = struct
  let t_of_yojson = function
    | `String "all" -> Ok "all"
    | `String "none" -> Ok "none"
    | `String "selected" -> Ok "selected"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Workflow = struct
  module Primary = struct
    module State = struct
      let t_of_yojson = function
        | `String "active" -> Ok "active"
        | `String "deleted" -> Ok "deleted"
        | `String "disabled_fork" -> Ok "disabled_fork"
        | `String "disabled_inactivity" -> Ok "disabled_inactivity"
        | `String "disabled_manually" -> Ok "disabled_manually"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      badge_url : string;
      created_at : string;
      deleted_at : string option; [@default None]
      html_url : string;
      id : int;
      name : string;
      node_id : string;
      path : string;
      state : State.t;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Enterprise = struct
  module Primary = struct
    type t = {
      avatar_url : string;
      created_at : string option;
      description : string option; [@default None]
      html_url : string;
      id : int;
      name : string;
      node_id : string;
      slug : string;
      updated_at : string option;
      website_url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module App_permissions = struct
  module Primary = struct
    module Actions = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Administration = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Checks = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Content_references = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Contents = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Deployments = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Environments = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Issues = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Members = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Metadata = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Organization_administration = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Organization_hooks = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Organization_packages = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Organization_plan = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Organization_projects = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | `String "admin" -> Ok "admin"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Organization_secrets = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Organization_self_hosted_runners = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Organization_user_blocking = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Packages = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Pages = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Pull_requests = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Repository_hooks = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Repository_projects = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | `String "admin" -> Ok "admin"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Secret_scanning_alerts = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Secrets = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Security_events = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Single_file = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Statuses = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Team_discussions = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Vulnerability_alerts = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Workflows = struct
      let t_of_yojson = function
        | `String "write" -> Ok "write"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      actions : Actions.t option; [@default None]
      administration : Administration.t option; [@default None]
      checks : Checks.t option; [@default None]
      content_references : Content_references.t option; [@default None]
      contents : Contents.t option; [@default None]
      deployments : Deployments.t option; [@default None]
      environments : Environments.t option; [@default None]
      issues : Issues.t option; [@default None]
      members : Members.t option; [@default None]
      metadata : Metadata.t option; [@default None]
      organization_administration : Organization_administration.t option; [@default None]
      organization_hooks : Organization_hooks.t option; [@default None]
      organization_packages : Organization_packages.t option; [@default None]
      organization_plan : Organization_plan.t option; [@default None]
      organization_projects : Organization_projects.t option; [@default None]
      organization_secrets : Organization_secrets.t option; [@default None]
      organization_self_hosted_runners : Organization_self_hosted_runners.t option; [@default None]
      organization_user_blocking : Organization_user_blocking.t option; [@default None]
      packages : Packages.t option; [@default None]
      pages : Pages.t option; [@default None]
      pull_requests : Pull_requests.t option; [@default None]
      repository_hooks : Repository_hooks.t option; [@default None]
      repository_projects : Repository_projects.t option; [@default None]
      secret_scanning_alerts : Secret_scanning_alerts.t option; [@default None]
      secrets : Secrets.t option; [@default None]
      security_events : Security_events.t option; [@default None]
      single_file : Single_file.t option; [@default None]
      statuses : Statuses.t option; [@default None]
      team_discussions : Team_discussions.t option; [@default None]
      vulnerability_alerts : Vulnerability_alerts.t option; [@default None]
      workflows : Workflows.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Scim_group_list_enterprise = struct
  module Primary = struct
    module Resources = struct
      module Items = struct
        module Primary = struct
          module Members = struct
            module Items = struct
              module Primary = struct
                type t = {
                  ref_ : string option; [@default None] [@key "$ref"]
                  display : string option; [@default None]
                  value : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
          end

          module Meta = struct
            module Primary = struct
              type t = {
                created : string option; [@default None]
                lastmodified : string option; [@default None] [@key "lastModified"]
                location : string option; [@default None]
                resourcetype : string option; [@default None] [@key "resourceType"]
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          module Schemas = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = {
            displayname : string option; [@default None] [@key "displayName"]
            externalid : string option; [@default None] [@key "externalId"]
            id : string;
            members : Members.t option; [@default None]
            meta : Meta.t option; [@default None]
            schemas : Schemas.t;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Schemas = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      resources : Resources.t; [@key "Resources"]
      itemsperpage : float; [@key "itemsPerPage"]
      schemas : Schemas.t;
      startindex : float; [@key "startIndex"]
      totalresults : float; [@key "totalResults"]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Content_tree = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          git : string option;
          html : string option;
          self : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Entries = struct
      module Items = struct
        module Primary = struct
          module Links_ = struct
            module Primary = struct
              type t = {
                git : string option;
                html : string option;
                self : string;
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = {
            links_ : Links_.t; [@key "_links"]
            content : string option; [@default None]
            download_url : string option;
            git_url : string option;
            html_url : string option;
            name : string;
            path : string;
            sha : string;
            size : int;
            type_ : string; [@key "type"]
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      download_url : string option;
      entries : Entries.t option; [@default None]
      git_url : string option;
      html_url : string option;
      name : string;
      path : string;
      sha : string;
      size : int;
      type_ : string; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Content_file = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          git : string option;
          html : string option;
          self : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      content : string;
      download_url : string option;
      encoding : string;
      git_url : string option;
      html_url : string option;
      name : string;
      path : string;
      sha : string;
      size : int;
      submodule_git_url : string option; [@default None]
      target : string option; [@default None]
      type_ : string; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Issue_event_project_card = struct
  module Primary = struct
    type t = {
      column_name : string;
      id : int;
      previous_column_name : string option; [@default None]
      project_id : int;
      project_url : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis_analysis_key = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Git_tree = struct
  module Primary = struct
    module Tree = struct
      module Items = struct
        module Primary = struct
          type t = {
            mode : string option; [@default None]
            path : string option; [@default None]
            sha : string option; [@default None]
            size : int option; [@default None]
            type_ : string option; [@default None] [@key "type"]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      sha : string;
      tree : Tree.t;
      truncated : bool;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Runner = struct
  module Primary = struct
    module Labels = struct
      module Items = struct
        module Primary = struct
          module Type = struct
            let t_of_yojson = function
              | `String "read-only" -> Ok "read-only"
              | `String "custom" -> Ok "custom"
              | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

            type t = (string[@of_yojson t_of_yojson])
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = {
            id : int option; [@default None]
            name : string option; [@default None]
            type_ : Type.t option; [@default None] [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      busy : bool;
      id : int;
      labels : Labels.t;
      name : string;
      os : string;
      status : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_of_conduct = struct
  module Primary = struct
    type t = {
      body : string option; [@default None]
      html_url : string option;
      key : string;
      name : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Api_overview = struct
  module Primary = struct
    module Actions = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Api = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Dependabot = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Git = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Hooks = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Importer = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Packages = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Pages = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Ssh_key_fingerprints = struct
      module Primary = struct
        type t = {
          sha256_dsa : string option; [@default None] [@key "SHA256_DSA"]
          sha256_ecdsa : string option; [@default None] [@key "SHA256_ECDSA"]
          sha256_ed25519 : string option; [@default None] [@key "SHA256_ED25519"]
          sha256_rsa : string option; [@default None] [@key "SHA256_RSA"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Web = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      actions : Actions.t option; [@default None]
      api : Api.t option; [@default None]
      dependabot : Dependabot.t option; [@default None]
      git : Git.t option; [@default None]
      hooks : Hooks.t option; [@default None]
      importer : Importer.t option; [@default None]
      packages : Packages.t option; [@default None]
      pages : Pages.t option; [@default None]
      ssh_key_fingerprints : Ssh_key_fingerprints.t option; [@default None]
      verifiable_password_authentication : bool;
      web : Web.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Alert_html_url = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Release_notes_content = struct
  module Primary = struct
    type t = {
      body : string;
      name : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Actions_public_key = struct
  module Primary = struct
    type t = {
      created_at : string option; [@default None]
      id : int option; [@default None]
      key : string;
      key_id : string;
      title : string option; [@default None]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Selected_actions_url = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Participation_stats = struct
  module Primary = struct
    module All = struct
      type t = int list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Owner = struct
      type t = int list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      all : All.t;
      owner : Owner.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Scim_enterprise_group = struct
  module Primary = struct
    module Members = struct
      module Items = struct
        module Primary = struct
          type t = {
            ref_ : string option; [@default None] [@key "$ref"]
            display : string option; [@default None]
            value : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Meta = struct
      module Primary = struct
        type t = {
          created : string option; [@default None]
          lastmodified : string option; [@default None] [@key "lastModified"]
          location : string option; [@default None]
          resourcetype : string option; [@default None] [@key "resourceType"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Schemas = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      displayname : string option; [@default None] [@key "displayName"]
      externalid : string option; [@default None] [@key "externalId"]
      id : string;
      members : Members.t option; [@default None]
      meta : Meta.t option; [@default None]
      schemas : Schemas.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Nullable_git_user = struct
  module Primary = struct
    type t = {
      date : string option; [@default None]
      email : string option; [@default None]
      name : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Organization_simple = struct
  module Primary = struct
    type t = {
      avatar_url : string;
      description : string option;
      events_url : string;
      hooks_url : string;
      id : int;
      issues_url : string;
      login : string;
      members_url : string;
      node_id : string;
      public_members_url : string;
      repos_url : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Pull_request_minimal = struct
  module Primary = struct
    module Base = struct
      module Primary = struct
        module Repo = struct
          module Primary = struct
            type t = {
              id : int;
              name : string;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          ref_ : string; [@key "ref"]
          repo : Repo.t;
          sha : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Head = struct
      module Primary = struct
        module Repo = struct
          module Primary = struct
            type t = {
              id : int;
              name : string;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          ref_ : string; [@key "ref"]
          repo : Repo.t;
          sha : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      base : Base.t;
      head : Head.t;
      id : int;
      number : int;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Deploy_key = struct
  module Primary = struct
    type t = {
      created_at : string;
      id : int;
      key : string;
      read_only : bool;
      title : string;
      url : string;
      verified : bool;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Content_traffic = struct
  module Primary = struct
    type t = {
      count : int;
      path : string;
      title : string;
      uniques : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Alert_instances_url = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Webhook_config_url = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Issue_event_dismissed_review = struct
  module Primary = struct
    type t = {
      dismissal_commit_id : string option; [@default None]
      dismissal_message : string option;
      review_id : int;
      state : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Import = struct
  module Primary = struct
    module Project_choices = struct
      module Items = struct
        module Primary = struct
          type t = {
            human_name : string option; [@default None]
            tfvc_project : string option; [@default None]
            vcs : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Status_ = struct
      let t_of_yojson = function
        | `String "auth" -> Ok "auth"
        | `String "error" -> Ok "error"
        | `String "none" -> Ok "none"
        | `String "detecting" -> Ok "detecting"
        | `String "choose" -> Ok "choose"
        | `String "auth_failed" -> Ok "auth_failed"
        | `String "importing" -> Ok "importing"
        | `String "mapping" -> Ok "mapping"
        | `String "waiting_to_push" -> Ok "waiting_to_push"
        | `String "pushing" -> Ok "pushing"
        | `String "complete" -> Ok "complete"
        | `String "setup" -> Ok "setup"
        | `String "unknown" -> Ok "unknown"
        | `String "detection_found_multiple" -> Ok "detection_found_multiple"
        | `String "detection_found_nothing" -> Ok "detection_found_nothing"
        | `String "detection_needs_auth" -> Ok "detection_needs_auth"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      authors_count : int option; [@default None]
      authors_url : string;
      commit_count : int option; [@default None]
      error_message : string option; [@default None]
      failed_step : string option; [@default None]
      has_large_files : bool option; [@default None]
      html_url : string;
      import_percent : int option; [@default None]
      large_files_count : int option; [@default None]
      large_files_size : int option; [@default None]
      message : string option; [@default None]
      project_choices : Project_choices.t option; [@default None]
      push_percent : int option; [@default None]
      repository_url : string;
      status : Status_.t;
      status_text : string option; [@default None]
      svc_root : string option; [@default None]
      svn_root : string option; [@default None]
      tfvc_project : string option; [@default None]
      url : string;
      use_lfs : bool option; [@default None]
      vcs : string option;
      vcs_url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Group_mapping = struct
  module Primary = struct
    module Groups = struct
      module Items = struct
        module Primary = struct
          type t = {
            group_description : string;
            group_id : string;
            group_name : string;
            status : string option; [@default None]
            synced_at : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = { groups : Groups.t option [@default None] }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Simple_user = struct
  module Primary = struct
    type t = {
      avatar_url : string;
      email : string option; [@default None]
      events_url : string;
      followers_url : string;
      following_url : string;
      gists_url : string;
      gravatar_id : string option;
      html_url : string;
      id : int;
      login : string;
      name : string option; [@default None]
      node_id : string;
      organizations_url : string;
      received_events_url : string;
      repos_url : string;
      site_admin : bool;
      starred_at : string option; [@default None]
      starred_url : string;
      subscriptions_url : string;
      type_ : string; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Runner_groups_enterprise = struct
  module Primary = struct
    type t = {
      allows_public_repositories : bool;
      default : bool;
      id : float;
      name : string;
      runners_url : string;
      selected_organizations_url : string option; [@default None]
      visibility : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Private_user = struct
  module Primary = struct
    module Plan = struct
      module Primary = struct
        type t = {
          collaborators : int;
          name : string;
          private_repos : int;
          space : int;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      avatar_url : string;
      bio : string option;
      blog : string option;
      business_plus : bool option; [@default None]
      collaborators : int;
      company : string option;
      created_at : string;
      disk_usage : int;
      email : string option;
      events_url : string;
      followers : int;
      followers_url : string;
      following : int;
      following_url : string;
      gists_url : string;
      gravatar_id : string option;
      hireable : bool option;
      html_url : string;
      id : int;
      ldap_dn : string option; [@default None]
      location : string option;
      login : string;
      name : string option;
      node_id : string;
      organizations_url : string;
      owned_private_repos : int;
      plan : Plan.t option; [@default None]
      private_gists : int;
      public_gists : int;
      public_repos : int;
      received_events_url : string;
      repos_url : string;
      site_admin : bool;
      starred_url : string;
      subscriptions_url : string;
      suspended_at : string option; [@default None]
      total_private_repos : int;
      twitter_username : string option; [@default None]
      two_factor_authentication : bool;
      type_ : string; [@key "type"]
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Topic = struct
  module Primary = struct
    module Names = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = { names : Names.t } [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Language = struct
  module Additional = struct
    type t = int [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
end

module Thread_subscription = struct
  module Primary = struct
    type t = {
      created_at : string option;
      ignored : bool;
      reason : string option;
      repository_url : string option; [@default None]
      subscribed : bool;
      thread_url : string option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Email = struct
  module Primary = struct
    type t = {
      email : string;
      primary : bool;
      verified : bool;
      visibility : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis_commit_sha = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Team_simple = struct
  module Primary = struct
    type t = {
      description : string option;
      html_url : string;
      id : int;
      ldap_dn : string option; [@default None]
      members_url : string;
      name : string;
      node_id : string;
      permission : string;
      privacy : string option; [@default None]
      repositories_url : string;
      slug : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Secret_scanning_alert_state = struct
  let t_of_yojson = function
    | `String "open" -> Ok "open"
    | `String "resolved" -> Ok "resolved"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Project_column = struct
  module Primary = struct
    type t = {
      cards_url : string;
      created_at : string;
      id : int;
      name : string;
      node_id : string;
      project_url : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Pages_source_hash = struct
  module Primary = struct
    type t = {
      branch : string;
      path : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Empty_object = struct
  type t = Json_schema.Empty_obj.t [@@deriving yojson { strict = false; meta = true }, show]
end

module Code_scanning_analysis_environment = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Check_annotation = struct
  module Primary = struct
    type t = {
      annotation_level : string option;
      blob_href : string;
      end_column : int option;
      end_line : int;
      message : string option;
      path : string;
      raw_details : string option;
      start_column : int option;
      start_line : int;
      title : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Simple_commit_status = struct
  module Primary = struct
    type t = {
      avatar_url : string option;
      context : string;
      created_at : string;
      description : string option;
      id : int;
      node_id : string;
      required : bool option; [@default None]
      state : string;
      target_url : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_alert_dismissed_reason = struct
  let t_of_yojson = function
    | `String "false positive" -> Ok "false positive"
    | `String "won't fix" -> Ok "won't fix"
    | `String "used in tests" -> Ok "used in tests"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson]) option
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Validation_error_simple = struct
  module Primary = struct
    module Errors = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      documentation_url : string;
      errors : Errors.t option; [@default None]
      message : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Pages_health_check = struct
  module Primary = struct
    module Alt_domain = struct
      module Primary = struct
        type t = {
          caa_error : string option; [@default None]
          dns_resolves : bool option; [@default None]
          enforces_https : bool option; [@default None]
          has_cname_record : bool option; [@default None]
          has_mx_records_present : bool option; [@default None]
          host : string option; [@default None]
          https_error : string option; [@default None]
          is_a_record : bool option; [@default None]
          is_apex_domain : bool option; [@default None]
          is_cloudflare_ip : bool option; [@default None]
          is_cname_to_fastly : bool option; [@default None]
          is_cname_to_github_user_domain : bool option; [@default None]
          is_cname_to_pages_dot_github_dot_com : bool option; [@default None]
          is_fastly_ip : bool option; [@default None]
          is_https_eligible : bool option; [@default None]
          is_non_github_pages_ip_present : bool option; [@default None]
          is_old_ip_address : bool option; [@default None]
          is_pages_domain : bool option; [@default None]
          is_pointed_to_github_pages_ip : bool option; [@default None]
          is_proxied : bool option; [@default None]
          is_served_by_pages : bool option; [@default None]
          is_valid : bool option; [@default None]
          is_valid_domain : bool option; [@default None]
          nameservers : string option; [@default None]
          reason : string option; [@default None]
          responds_to_https : bool option; [@default None]
          should_be_a_record : bool option; [@default None]
          uri : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Domain = struct
      module Primary = struct
        type t = {
          caa_error : string option; [@default None]
          dns_resolves : bool option; [@default None]
          enforces_https : bool option; [@default None]
          has_cname_record : bool option; [@default None]
          has_mx_records_present : bool option; [@default None]
          host : string option; [@default None]
          https_error : string option; [@default None]
          is_a_record : bool option; [@default None]
          is_apex_domain : bool option; [@default None]
          is_cloudflare_ip : bool option; [@default None]
          is_cname_to_fastly : bool option; [@default None]
          is_cname_to_github_user_domain : bool option; [@default None]
          is_cname_to_pages_dot_github_dot_com : bool option; [@default None]
          is_fastly_ip : bool option; [@default None]
          is_https_eligible : bool option; [@default None]
          is_non_github_pages_ip_present : bool option; [@default None]
          is_old_ip_address : bool option; [@default None]
          is_pages_domain : bool option; [@default None]
          is_pointed_to_github_pages_ip : bool option; [@default None]
          is_proxied : bool option; [@default None]
          is_served_by_pages : bool option; [@default None]
          is_valid : bool option; [@default None]
          is_valid_domain : bool option; [@default None]
          nameservers : string option; [@default None]
          reason : string option; [@default None]
          responds_to_https : bool option; [@default None]
          should_be_a_record : bool option; [@default None]
          uri : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      alt_domain : Alt_domain.t option; [@default None]
      domain : Domain.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis_category = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Interaction_expiry = struct
  let t_of_yojson = function
    | `String "one_day" -> Ok "one_day"
    | `String "three_days" -> Ok "three_days"
    | `String "one_week" -> Ok "one_week"
    | `String "one_month" -> Ok "one_month"
    | `String "six_months" -> Ok "six_months"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Author_association = struct
  let t_of_yojson = function
    | `String "COLLABORATOR" -> Ok "COLLABORATOR"
    | `String "CONTRIBUTOR" -> Ok "CONTRIBUTOR"
    | `String "FIRST_TIMER" -> Ok "FIRST_TIMER"
    | `String "FIRST_TIME_CONTRIBUTOR" -> Ok "FIRST_TIME_CONTRIBUTOR"
    | `String "MANNEQUIN" -> Ok "MANNEQUIN"
    | `String "MEMBER" -> Ok "MEMBER"
    | `String "NONE" -> Ok "NONE"
    | `String "OWNER" -> Ok "OWNER"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Content_symlink = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          git : string option;
          html : string option;
          self : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      download_url : string option;
      git_url : string option;
      html_url : string option;
      name : string;
      path : string;
      sha : string;
      size : int;
      target : string;
      type_ : string; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Tag = struct
  module Primary = struct
    module Commit_ = struct
      module Primary = struct
        type t = {
          sha : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      commit : Commit_.t;
      name : string;
      node_id : string;
      tarball_url : string;
      zipball_url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Porter_author = struct
  module Primary = struct
    type t = {
      email : string;
      id : int;
      import_url : string;
      name : string;
      remote_id : string;
      remote_name : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Actions_enabled = struct
  type t = bool [@@deriving yojson { strict = false; meta = true }, show]
end

module Organization_actions_secret = struct
  module Primary = struct
    module Visibility = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "private" -> Ok "private"
        | `String "selected" -> Ok "selected"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      created_at : string;
      name : string;
      selected_repositories_url : string option; [@default None]
      updated_at : string;
      visibility : Visibility.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Issue_event_milestone = struct
  module Primary = struct
    type t = { title : string } [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Timeline_committed_event = struct
  module Primary = struct
    module Author = struct
      module Primary = struct
        type t = {
          date : string;
          email : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Committer = struct
      module Primary = struct
        type t = {
          date : string;
          email : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Parents = struct
      module Items = struct
        module Primary = struct
          type t = {
            html_url : string;
            sha : string;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Tree = struct
      module Primary = struct
        type t = {
          sha : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Verification_ = struct
      module Primary = struct
        type t = {
          payload : string option;
          reason : string;
          signature : string option;
          verified : bool;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      author : Author.t;
      committer : Committer.t;
      event : string option; [@default None]
      html_url : string;
      message : string;
      node_id : string;
      parents : Parents.t;
      sha : string;
      tree : Tree.t;
      url : string;
      verification : Verification_.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Key_simple = struct
  module Primary = struct
    type t = {
      id : int;
      key : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_of_conduct_simple = struct
  module Primary = struct
    type t = {
      html_url : string option;
      key : string;
      name : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Porter_large_file = struct
  module Primary = struct
    type t = {
      oid : string;
      path : string;
      ref_name : string;
      size : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Packages_billing_usage = struct
  module Primary = struct
    type t = {
      included_gigabytes_bandwidth : int;
      total_gigabytes_bandwidth_used : int;
      total_paid_gigabytes_bandwidth_used : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Basic_error = struct
  module Primary = struct
    type t = {
      documentation_url : string option; [@default None]
      message : string option; [@default None]
      status : string option; [@default None]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Issue_event_rename = struct
  module Primary = struct
    type t = {
      from : string;
      to_ : string; [@key "to"]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Enabled_organizations = struct
  let t_of_yojson = function
    | `String "all" -> Ok "all"
    | `String "none" -> Ok "none"
    | `String "selected" -> Ok "selected"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Autolink = struct
  module Primary = struct
    type t = {
      id : int;
      key_prefix : string;
      url_template : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Link = struct
  module Primary = struct
    type t = { href : string } [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Workflow_run_usage = struct
  module Primary = struct
    module Billable = struct
      module Primary = struct
        module MACOS = struct
          module Primary = struct
            module Job_runs = struct
              module Items = struct
                module Primary = struct
                  type t = {
                    duration_ms : int;
                    job_id : int;
                  }
                  [@@deriving yojson { strict = false; meta = true }, show]
                end

                include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
              end

              type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = {
              job_runs : Job_runs.t option; [@default None]
              jobs : int;
              total_ms : int;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module UBUNTU = struct
          module Primary = struct
            module Job_runs = struct
              module Items = struct
                module Primary = struct
                  type t = {
                    duration_ms : int;
                    job_id : int;
                  }
                  [@@deriving yojson { strict = false; meta = true }, show]
                end

                include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
              end

              type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = {
              job_runs : Job_runs.t option; [@default None]
              jobs : int;
              total_ms : int;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module WINDOWS = struct
          module Primary = struct
            module Job_runs = struct
              module Items = struct
                module Primary = struct
                  type t = {
                    duration_ms : int;
                    job_id : int;
                  }
                  [@@deriving yojson { strict = false; meta = true }, show]
                end

                include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
              end

              type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = {
              job_runs : Job_runs.t option; [@default None]
              jobs : int;
              total_ms : int;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          macos : MACOS.t option; [@default None] [@key "MACOS"]
          ubuntu : UBUNTU.t option; [@default None] [@key "UBUNTU"]
          windows : WINDOWS.t option; [@default None] [@key "WINDOWS"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      billable : Billable.t;
      run_duration_ms : int option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Runner_groups_org = struct
  module Primary = struct
    type t = {
      allows_public_repositories : bool;
      default : bool;
      id : float;
      inherited : bool;
      inherited_allows_public_repositories : bool option; [@default None]
      name : string;
      runners_url : string;
      selected_repositories_url : string option; [@default None]
      visibility : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Org_hook = struct
  module Primary = struct
    module Config = struct
      module Primary = struct
        type t = {
          content_type : string option; [@default None]
          insecure_ssl : string option; [@default None]
          secret : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Events = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      active : bool;
      config : Config.t;
      created_at : string;
      deliveries_url : string option; [@default None]
      events : Events.t;
      id : int;
      name : string;
      ping_url : string;
      type_ : string; [@key "type"]
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Alert_number = struct
  type t = int [@@deriving yojson { strict = false; meta = true }, show]
end

module Artifact = struct
  module Primary = struct
    type t = {
      archive_download_url : string;
      created_at : string option;
      expired : bool;
      expires_at : string option;
      id : int;
      name : string;
      node_id : string;
      size_in_bytes : int;
      updated_at : string option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Deployment_branch_policy = struct
  module Primary = struct
    type t = {
      custom_branch_policies : bool;
      protected_branches : bool;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Workflow_usage = struct
  module Primary = struct
    module Billable = struct
      module Primary = struct
        module MACOS = struct
          module Primary = struct
            type t = { total_ms : int option [@default None] }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module UBUNTU = struct
          module Primary = struct
            type t = { total_ms : int option [@default None] }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module WINDOWS = struct
          module Primary = struct
            type t = { total_ms : int option [@default None] }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          macos : MACOS.t option; [@default None] [@key "MACOS"]
          ubuntu : UBUNTU.t option; [@default None] [@key "UBUNTU"]
          windows : WINDOWS.t option; [@default None] [@key "WINDOWS"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = { billable : Billable.t } [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Nullable_simple_commit = struct
  module Primary = struct
    module Author = struct
      module Primary = struct
        type t = {
          email : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Committer = struct
      module Primary = struct
        type t = {
          email : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      author : Author.t option;
      committer : Committer.t option;
      id : string;
      message : string;
      timestamp : string;
      tree_id : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_ref = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Search_result_text_matches = struct
  module Items = struct
    module Primary = struct
      module Matches = struct
        module Items = struct
          module Primary = struct
            module Indices = struct
              type t = int list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = {
              indices : Indices.t option; [@default None]
              text : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = {
        fragment : string option; [@default None]
        matches : Matches.t option; [@default None]
        object_type : string option; [@default None]
        object_url : string option; [@default None]
        property : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

module Code_scanning_analysis_sarif_file = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module Audit_log_event = struct
  module Primary = struct
    module Actor_location = struct
      module Primary = struct
        type t = { country_name : string option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Config = struct
      module Items = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Config_was = struct
      module Items = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Data = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    module Events = struct
      module Items = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Events_were = struct
      module Items = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      timestamp_ : int option; [@default None] [@key "@timestamp"]
      document_id_ : string option; [@default None] [@key "_document_id"]
      action : string option; [@default None]
      active : bool option; [@default None]
      active_was : bool option; [@default None]
      actor : string option; [@default None]
      actor_id : int option; [@default None]
      actor_location : Actor_location.t option; [@default None]
      blocked_user : string option; [@default None]
      business : string option; [@default None]
      config : Config.t option; [@default None]
      config_was : Config_was.t option; [@default None]
      content_type : string option; [@default None]
      created_at : int option; [@default None]
      data : Data.t option; [@default None]
      deploy_key_fingerprint : string option; [@default None]
      emoji : string option; [@default None]
      events : Events.t option; [@default None]
      events_were : Events_were.t option; [@default None]
      explanation : string option; [@default None]
      fingerprint : string option; [@default None]
      hook_id : int option; [@default None]
      limited_availability : bool option; [@default None]
      message : string option; [@default None]
      name : string option; [@default None]
      old_user : string option; [@default None]
      openssh_public_key : string option; [@default None]
      org : string option; [@default None]
      org_id : int option; [@default None]
      previous_visibility : string option; [@default None]
      read_only : bool option; [@default None]
      repo : string option; [@default None]
      repository : string option; [@default None]
      repository_public : bool option; [@default None]
      target_login : string option; [@default None]
      team : string option; [@default None]
      transport_protocol : int option; [@default None]
      transport_protocol_name : string option; [@default None]
      user : string option; [@default None]
      visibility : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Runner_application = struct
  module Primary = struct
    type t = {
      architecture : string;
      download_url : string;
      filename : string;
      os : string;
      sha256_checksum : string option; [@default None]
      temp_download_token : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_alert_set_state = struct
  let t_of_yojson = function
    | `String "open" -> Ok "open"
    | `String "dismissed" -> Ok "dismissed"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Scim_error = struct
  module Primary = struct
    module Schemas = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      detail : string option; [@default None]
      documentation_url : string option; [@default None]
      message : string option; [@default None]
      schemas : Schemas.t option; [@default None]
      scimtype : string option; [@default None] [@key "scimType"]
      status : int option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Traffic = struct
  module Primary = struct
    type t = {
      count : int;
      timestamp : string;
      uniques : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Credential_authorization = struct
  module Primary = struct
    module Scopes = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      authorized_credential_id : int option; [@default None]
      authorized_credential_note : string option; [@default None]
      authorized_credential_title : string option; [@default None]
      credential_accessed_at : string option; [@default None]
      credential_authorized_at : string;
      credential_id : int;
      credential_type : string;
      fingerprint : string option; [@default None]
      login : string;
      scopes : Scopes.t option; [@default None]
      token_last_eight : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_sarifs_status = struct
  module Primary = struct
    module Processing_status = struct
      let t_of_yojson = function
        | `String "pending" -> Ok "pending"
        | `String "complete" -> Ok "complete"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      analyses_url : string option; [@default None]
      processing_status : Processing_status.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Blob = struct
  module Primary = struct
    type t = {
      content : string;
      encoding : string;
      highlighted_content : string option; [@default None]
      node_id : string;
      sha : string;
      size : int option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module License = struct
  module Primary = struct
    module Conditions = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Limitations = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Permissions = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      body : string;
      conditions : Conditions.t;
      description : string;
      featured : bool;
      html_url : string;
      implementation : string;
      key : string;
      limitations : Limitations.t;
      name : string;
      node_id : string;
      permissions : Permissions.t;
      spdx_id : string option;
      url : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Status_check_policy = struct
  module Primary = struct
    module Contexts = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      contexts : Contexts.t;
      contexts_url : string;
      strict : bool;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Git_commit = struct
  module Primary = struct
    module Author = struct
      module Primary = struct
        type t = {
          date : string;
          email : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Committer = struct
      module Primary = struct
        type t = {
          date : string;
          email : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Parents = struct
      module Items = struct
        module Primary = struct
          type t = {
            html_url : string;
            sha : string;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Tree = struct
      module Primary = struct
        type t = {
          sha : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Verification_ = struct
      module Primary = struct
        type t = {
          payload : string option;
          reason : string;
          signature : string option;
          verified : bool;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      author : Author.t;
      committer : Committer.t;
      html_url : string;
      message : string;
      node_id : string;
      parents : Parents.t;
      sha : string;
      tree : Tree.t;
      url : string;
      verification : Verification_.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Actions_secret = struct
  module Primary = struct
    type t = {
      created_at : string;
      name : string;
      updated_at : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Marketplace_listing_plan = struct
  module Primary = struct
    module Bullets = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      accounts_url : string;
      bullets : Bullets.t;
      description : string;
      has_free_trial : bool;
      id : int;
      monthly_price_in_cents : int;
      name : string;
      number : int;
      price_model : string;
      state : string;
      unit_name : string option;
      url : string;
      yearly_price_in_cents : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Rate_limit_overview = struct
  module Primary = struct
    module Resources = struct
      module Primary = struct
        type t = {
          actions_runner_registration : Rate_limit.t option; [@default None]
          code_scanning_upload : Rate_limit.t option; [@default None]
          core : Rate_limit.t;
          graphql : Rate_limit.t option; [@default None]
          integration_manifest : Rate_limit.t option; [@default None]
          search : Rate_limit.t;
          source_import : Rate_limit.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      rate : Rate_limit.t;
      resources : Resources.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Git_tag = struct
  module Primary = struct
    module Object = struct
      module Primary = struct
        type t = {
          sha : string;
          type_ : string; [@key "type"]
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Tagger = struct
      module Primary = struct
        type t = {
          date : string;
          email : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      message : string;
      node_id : string;
      object_ : Object.t; [@key "object"]
      sha : string;
      tag : string;
      tagger : Tagger.t;
      url : string;
      verification : Verification.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Interaction_limit_response = struct
  module Primary = struct
    type t = {
      expires_at : string;
      limit : Interaction_group.t;
      origin : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Gist_commit = struct
  module Primary = struct
    module Change_status = struct
      module Primary = struct
        type t = {
          additions : int option; [@default None]
          deletions : int option; [@default None]
          total : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      change_status : Change_status.t;
      committed_at : string;
      url : string;
      user : Nullable_simple_user.t option;
      version : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Team_discussion_comment = struct
  module Primary = struct
    type t = {
      author : Nullable_simple_user.t option;
      body : string;
      body_html : string;
      body_version : string;
      created_at : string;
      discussion_url : string;
      html_url : string;
      last_edited_at : string option;
      node_id : string;
      number : int;
      reactions : Reaction_rollup.t option; [@default None]
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Nullable_milestone = struct
  module Primary = struct
    module State = struct
      let t_of_yojson = function
        | `String "open" -> Ok "open"
        | `String "closed" -> Ok "closed"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      closed_at : string option;
      closed_issues : int;
      created_at : string;
      creator : Nullable_simple_user.t option;
      description : string option;
      due_on : string option;
      html_url : string;
      id : int;
      labels_url : string;
      node_id : string;
      number : int;
      open_issues : int;
      state : State.t; [@default "open"]
      title : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Application_grant = struct
  module Primary = struct
    module App = struct
      module Primary = struct
        type t = {
          client_id : string;
          name : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Scopes = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      app : App.t;
      created_at : string;
      id : int;
      scopes : Scopes.t;
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Release_asset = struct
  module Primary = struct
    module State = struct
      let t_of_yojson = function
        | `String "uploaded" -> Ok "uploaded"
        | `String "open" -> Ok "open"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      browser_download_url : string;
      content_type : string;
      created_at : string;
      download_count : int;
      id : int;
      label : string option;
      name : string;
      node_id : string;
      size : int;
      state : State.t;
      updated_at : string;
      uploader : Nullable_simple_user.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Contributor_activity = struct
  module Primary = struct
    module Weeks = struct
      module Items = struct
        module Primary = struct
          type t = {
            a : int option; [@default None]
            c : int option; [@default None]
            d : int option; [@default None]
            w : int option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      author : Nullable_simple_user.t option;
      total : int;
      weeks : Weeks.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Status = struct
  module Primary = struct
    type t = {
      avatar_url : string option;
      context : string;
      created_at : string;
      creator : Nullable_simple_user.t option;
      description : string;
      id : int;
      node_id : string;
      state : string;
      target_url : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Integration = struct
  module Primary = struct
    module Events = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Permissions = struct
      module Primary = struct
        type t = {
          checks : string option; [@default None]
          contents : string option; [@default None]
          deployments : string option; [@default None]
          issues : string option; [@default None]
          metadata : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Additional = struct
        type t = string [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Additional)
    end

    type t = {
      client_id : string option; [@default None]
      client_secret : string option; [@default None]
      created_at : string;
      description : string option;
      events : Events.t;
      external_url : string;
      html_url : string;
      id : int;
      installations_count : int option; [@default None]
      name : string;
      node_id : string;
      owner : Nullable_simple_user.t option;
      pem : string option; [@default None]
      permissions : Permissions.t;
      slug : string option; [@default None]
      updated_at : string;
      webhook_secret : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Repository_collaborator_permission = struct
  module Primary = struct
    type t = {
      permission : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Team_discussion = struct
  module Primary = struct
    type t = {
      author : Nullable_simple_user.t option;
      body : string;
      body_html : string;
      body_version : string;
      comments_count : int;
      comments_url : string;
      created_at : string;
      html_url : string;
      last_edited_at : string option;
      node_id : string;
      number : int;
      pinned : bool;
      private_ : bool; [@key "private"]
      reactions : Reaction_rollup.t option; [@default None]
      team_url : string;
      title : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Nullable_integration = struct
  module Primary = struct
    module Events = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Permissions = struct
      module Primary = struct
        type t = {
          checks : string option; [@default None]
          contents : string option; [@default None]
          deployments : string option; [@default None]
          issues : string option; [@default None]
          metadata : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      module Additional = struct
        type t = string [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Additional)
    end

    type t = {
      client_id : string option; [@default None]
      client_secret : string option; [@default None]
      created_at : string;
      description : string option;
      events : Events.t;
      external_url : string;
      html_url : string;
      id : int;
      installations_count : int option; [@default None]
      name : string;
      node_id : string;
      owner : Nullable_simple_user.t option;
      pem : string option; [@default None]
      permissions : Permissions.t;
      slug : string option; [@default None]
      updated_at : string;
      webhook_secret : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Reaction = struct
  module Primary = struct
    module Content = struct
      let t_of_yojson = function
        | `String "+1" -> Ok "+1"
        | `String "-1" -> Ok "-1"
        | `String "laugh" -> Ok "laugh"
        | `String "confused" -> Ok "confused"
        | `String "heart" -> Ok "heart"
        | `String "hooray" -> Ok "hooray"
        | `String "rocket" -> Ok "rocket"
        | `String "eyes" -> Ok "eyes"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      content : Content.t;
      created_at : string;
      id : int;
      node_id : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Page_build = struct
  module Primary = struct
    module Error = struct
      module Primary = struct
        type t = { message : string option }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      commit : string;
      created_at : string;
      duration : int;
      error : Error.t;
      pusher : Nullable_simple_user.t option;
      status : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Milestone = struct
  module Primary = struct
    module State = struct
      let t_of_yojson = function
        | `String "open" -> Ok "open"
        | `String "closed" -> Ok "closed"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      closed_at : string option;
      closed_issues : int;
      created_at : string;
      creator : Nullable_simple_user.t option;
      description : string option;
      due_on : string option;
      html_url : string;
      id : int;
      labels_url : string;
      node_id : string;
      number : int;
      open_issues : int;
      state : State.t; [@default "open"]
      title : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Gist_history = struct
  module Primary = struct
    module Change_status = struct
      module Primary = struct
        type t = {
          additions : int option; [@default None]
          deletions : int option; [@default None]
          total : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      change_status : Change_status.t option; [@default None]
      committed_at : string option; [@default None]
      url : string option; [@default None]
      user : Nullable_simple_user.t option; [@default None]
      version : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Stargazer = struct
  module Primary = struct
    type t = {
      starred_at : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Project_card = struct
  module Primary = struct
    type t = {
      archived : bool option; [@default None]
      column_name : string option; [@default None]
      column_url : string;
      content_url : string option; [@default None]
      created_at : string;
      creator : Nullable_simple_user.t option;
      id : int;
      node_id : string;
      note : string option;
      project_id : string option; [@default None]
      project_url : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Project = struct
  module Primary = struct
    module Organization_permission = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | `String "admin" -> Ok "admin"
        | `String "none" -> Ok "none"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      body : string option;
      columns_url : string;
      created_at : string;
      creator : Nullable_simple_user.t option;
      html_url : string;
      id : int;
      name : string;
      node_id : string;
      number : int;
      organization_permission : Organization_permission.t option; [@default None]
      owner_url : string;
      private_ : bool option; [@default None] [@key "private"]
      state : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_sarifs_receipt = struct
  module Primary = struct
    type t = {
      id : string option; [@default None]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Team = struct
  module Primary = struct
    module Permissions = struct
      module Primary = struct
        type t = {
          admin : bool;
          maintain : bool;
          pull : bool;
          push : bool;
          triage : bool;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      description : string option;
      html_url : string;
      id : int;
      members_url : string;
      name : string;
      node_id : string;
      parent : Nullable_team_simple.t option;
      permission : string;
      permissions : Permissions.t option; [@default None]
      privacy : string option; [@default None]
      repositories_url : string;
      slug : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Team_full = struct
  module Primary = struct
    module Privacy = struct
      let t_of_yojson = function
        | `String "closed" -> Ok "closed"
        | `String "secret" -> Ok "secret"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      created_at : string;
      description : string option;
      html_url : string;
      id : int;
      ldap_dn : string option; [@default None]
      members_count : int;
      members_url : string;
      name : string;
      node_id : string;
      organization : Organization_full.t;
      parent : Nullable_team_simple.t option; [@default None]
      permission : string;
      privacy : Privacy.t option; [@default None]
      repos_count : int;
      repositories_url : string;
      slug : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Community_profile = struct
  module Primary = struct
    module Files = struct
      module Primary = struct
        type t = {
          code_of_conduct : Nullable_code_of_conduct_simple.t option;
          code_of_conduct_file : Nullable_community_health_file.t option;
          contributing : Nullable_community_health_file.t option;
          issue_template : Nullable_community_health_file.t option;
          license : Nullable_license_simple.t option;
          pull_request_template : Nullable_community_health_file.t option;
          readme : Nullable_community_health_file.t option;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      content_reports_enabled : bool option; [@default None]
      description : string option;
      documentation : string option;
      files : Files.t;
      health_percentage : int;
      updated_at : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module License_content = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          git : string option;
          html : string option;
          self : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      content : string;
      download_url : string option;
      encoding : string;
      git_url : string option;
      html_url : string option;
      license : Nullable_license_simple.t option;
      name : string;
      path : string;
      sha : string;
      size : int;
      type_ : string; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Feed = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        module Current_user_organizations = struct
          type t = Link_with_type.t list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          current_user : Link_with_type.t option; [@default None]
          current_user_actor : Link_with_type.t option; [@default None]
          current_user_organization : Link_with_type.t option; [@default None]
          current_user_organizations : Current_user_organizations.t option; [@default None]
          current_user_public : Link_with_type.t option; [@default None]
          security_advisories : Link_with_type.t option; [@default None]
          timeline : Link_with_type.t;
          user : Link_with_type.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Current_user_organization_urls = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      current_user_actor_url : string option; [@default None]
      current_user_organization_url : string option; [@default None]
      current_user_organization_urls : Current_user_organization_urls.t option; [@default None]
      current_user_public_url : string option; [@default None]
      current_user_url : string option; [@default None]
      security_advisories_url : string option; [@default None]
      timeline_url : string;
      user_url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Scim_user_list = struct
  module Primary = struct
    module Resources = struct
      type t = Scim_user.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Schemas = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      resources : Resources.t; [@key "Resources"]
      itemsperpage : int; [@key "itemsPerPage"]
      schemas : Schemas.t;
      startindex : int; [@key "startIndex"]
      totalresults : int; [@key "totalResults"]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis_tool = struct
  module Primary = struct
    type t = {
      guid : string option; [@default None]
      name : string option; [@default None]
      version : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Actions_organization_permissions = struct
  module Primary = struct
    type t = {
      allowed_actions : Allowed_actions.t option; [@default None]
      enabled_repositories : Enabled_repositories.t;
      selected_actions_url : string option; [@default None]
      selected_repositories_url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Commit = struct
  module Primary = struct
    module Commit_ = struct
      module Primary = struct
        module Tree = struct
          module Primary = struct
            type t = {
              sha : string;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          author : Nullable_git_user.t option;
          comment_count : int;
          committer : Nullable_git_user.t option;
          message : string;
          tree : Tree.t;
          url : string;
          verification : Verification.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Files = struct
      module Items = struct
        module Primary = struct
          type t = {
            additions : int option; [@default None]
            blob_url : string option; [@default None]
            changes : int option; [@default None]
            contents_url : string option; [@default None]
            deletions : int option; [@default None]
            filename : string option; [@default None]
            patch : string option; [@default None]
            previous_filename : string option; [@default None]
            raw_url : string option; [@default None]
            sha : string option; [@default None]
            status : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Parents = struct
      module Items = struct
        module Primary = struct
          type t = {
            html_url : string option; [@default None]
            sha : string;
            url : string;
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Stats = struct
      module Primary = struct
        type t = {
          additions : int option; [@default None]
          deletions : int option; [@default None]
          total : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      author : Nullable_simple_user.t option;
      comments_url : string;
      commit : Commit_.t;
      committer : Nullable_simple_user.t option;
      files : Files.t option; [@default None]
      html_url : string;
      node_id : string;
      parents : Parents.t;
      sha : string;
      stats : Stats.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Org_membership = struct
  module Primary = struct
    module Permissions = struct
      module Primary = struct
        type t = { can_create_repository : bool }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Role = struct
      let t_of_yojson = function
        | `String "admin" -> Ok "admin"
        | `String "member" -> Ok "member"
        | `String "billing_manager" -> Ok "billing_manager"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module State = struct
      let t_of_yojson = function
        | `String "active" -> Ok "active"
        | `String "pending" -> Ok "pending"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      organization : Organization_simple.t;
      organization_url : string;
      permissions : Permissions.t option; [@default None]
      role : Role.t;
      state : State.t;
      url : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Webhook_config = struct
  module Primary = struct
    type t = {
      content_type : string option; [@default None]
      insecure_ssl : Webhook_config_insecure_ssl.t option; [@default None]
      secret : string option; [@default None]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Hook = struct
  module Primary = struct
    module Config = struct
      module Primary = struct
        type t = {
          content_type : string option; [@default None]
          digest : string option; [@default None]
          email : string option; [@default None]
          insecure_ssl : Webhook_config_insecure_ssl.t option; [@default None]
          password : string option; [@default None]
          room : string option; [@default None]
          secret : string option; [@default None]
          subdomain : string option; [@default None]
          token : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Events = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      active : bool;
      config : Config.t;
      created_at : string;
      deliveries_url : string option; [@default None]
      events : Events.t;
      id : int;
      last_response : Hook_response.t;
      name : string;
      ping_url : string;
      test_url : string;
      type_ : string; [@key "type"]
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Repository = struct
  module Primary = struct
    module Permissions = struct
      module Primary = struct
        type t = {
          admin : bool;
          maintain : bool option; [@default None]
          pull : bool;
          push : bool;
          triage : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Template_repository = struct
      module Primary = struct
        module Owner = struct
          module Primary = struct
            type t = {
              avatar_url : string option; [@default None]
              events_url : string option; [@default None]
              followers_url : string option; [@default None]
              following_url : string option; [@default None]
              gists_url : string option; [@default None]
              gravatar_id : string option; [@default None]
              html_url : string option; [@default None]
              id : int option; [@default None]
              login : string option; [@default None]
              node_id : string option; [@default None]
              organizations_url : string option; [@default None]
              received_events_url : string option; [@default None]
              repos_url : string option; [@default None]
              site_admin : bool option; [@default None]
              starred_url : string option; [@default None]
              subscriptions_url : string option; [@default None]
              type_ : string option; [@default None] [@key "type"]
              url : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Permissions = struct
          module Primary = struct
            type t = {
              admin : bool option; [@default None]
              maintain : bool option; [@default None]
              pull : bool option; [@default None]
              push : bool option; [@default None]
              triage : bool option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Topics = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          allow_auto_merge : bool option; [@default None]
          allow_merge_commit : bool option; [@default None]
          allow_rebase_merge : bool option; [@default None]
          allow_squash_merge : bool option; [@default None]
          archive_url : string option; [@default None]
          archived : bool option; [@default None]
          assignees_url : string option; [@default None]
          blobs_url : string option; [@default None]
          branches_url : string option; [@default None]
          clone_url : string option; [@default None]
          collaborators_url : string option; [@default None]
          comments_url : string option; [@default None]
          commits_url : string option; [@default None]
          compare_url : string option; [@default None]
          contents_url : string option; [@default None]
          contributors_url : string option; [@default None]
          created_at : string option; [@default None]
          default_branch : string option; [@default None]
          delete_branch_on_merge : bool option; [@default None]
          deployments_url : string option; [@default None]
          description : string option; [@default None]
          disabled : bool option; [@default None]
          downloads_url : string option; [@default None]
          events_url : string option; [@default None]
          fork : bool option; [@default None]
          forks_count : int option; [@default None]
          forks_url : string option; [@default None]
          full_name : string option; [@default None]
          git_commits_url : string option; [@default None]
          git_refs_url : string option; [@default None]
          git_tags_url : string option; [@default None]
          git_url : string option; [@default None]
          has_downloads : bool option; [@default None]
          has_issues : bool option; [@default None]
          has_pages : bool option; [@default None]
          has_projects : bool option; [@default None]
          has_wiki : bool option; [@default None]
          homepage : string option; [@default None]
          hooks_url : string option; [@default None]
          html_url : string option; [@default None]
          id : int option; [@default None]
          is_template : bool option; [@default None]
          issue_comment_url : string option; [@default None]
          issue_events_url : string option; [@default None]
          issues_url : string option; [@default None]
          keys_url : string option; [@default None]
          labels_url : string option; [@default None]
          language : string option; [@default None]
          languages_url : string option; [@default None]
          merges_url : string option; [@default None]
          milestones_url : string option; [@default None]
          mirror_url : string option; [@default None]
          name : string option; [@default None]
          network_count : int option; [@default None]
          node_id : string option; [@default None]
          notifications_url : string option; [@default None]
          open_issues_count : int option; [@default None]
          owner : Owner.t option; [@default None]
          permissions : Permissions.t option; [@default None]
          private_ : bool option; [@default None] [@key "private"]
          pulls_url : string option; [@default None]
          pushed_at : string option; [@default None]
          releases_url : string option; [@default None]
          size : int option; [@default None]
          ssh_url : string option; [@default None]
          stargazers_count : int option; [@default None]
          stargazers_url : string option; [@default None]
          statuses_url : string option; [@default None]
          subscribers_count : int option; [@default None]
          subscribers_url : string option; [@default None]
          subscription_url : string option; [@default None]
          svn_url : string option; [@default None]
          tags_url : string option; [@default None]
          teams_url : string option; [@default None]
          temp_clone_token : string option; [@default None]
          topics : Topics.t option; [@default None]
          trees_url : string option; [@default None]
          updated_at : string option; [@default None]
          url : string option; [@default None]
          visibility : string option; [@default None]
          watchers_count : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Topics = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      allow_auto_merge : bool; [@default false]
      allow_forking : bool option; [@default None]
      allow_merge_commit : bool; [@default true]
      allow_rebase_merge : bool; [@default true]
      allow_squash_merge : bool; [@default true]
      archive_url : string;
      archived : bool; [@default false]
      assignees_url : string;
      blobs_url : string;
      branches_url : string;
      clone_url : string;
      collaborators_url : string;
      comments_url : string;
      commits_url : string;
      compare_url : string;
      contents_url : string;
      contributors_url : string;
      created_at : string option;
      default_branch : string;
      delete_branch_on_merge : bool; [@default false]
      deployments_url : string;
      description : string option;
      disabled : bool;
      downloads_url : string;
      events_url : string;
      fork : bool;
      forks : int;
      forks_count : int;
      forks_url : string;
      full_name : string;
      git_commits_url : string;
      git_refs_url : string;
      git_tags_url : string;
      git_url : string;
      has_downloads : bool; [@default true]
      has_issues : bool; [@default true]
      has_pages : bool;
      has_projects : bool; [@default true]
      has_wiki : bool; [@default true]
      homepage : string option;
      hooks_url : string;
      html_url : string;
      id : int;
      is_template : bool; [@default false]
      issue_comment_url : string;
      issue_events_url : string;
      issues_url : string;
      keys_url : string;
      labels_url : string;
      language : string option;
      languages_url : string;
      license : Nullable_license_simple.t option;
      master_branch : string option; [@default None]
      merges_url : string;
      milestones_url : string;
      mirror_url : string option;
      name : string;
      network_count : int option; [@default None]
      node_id : string;
      notifications_url : string;
      open_issues : int;
      open_issues_count : int;
      organization : Nullable_simple_user.t option; [@default None]
      owner : Simple_user.t;
      permissions : Permissions.t option; [@default None]
      private_ : bool; [@default false] [@key "private"]
      pulls_url : string;
      pushed_at : string option;
      releases_url : string;
      size : int;
      ssh_url : string;
      stargazers_count : int;
      stargazers_url : string;
      starred_at : string option; [@default None]
      statuses_url : string;
      subscribers_count : int option; [@default None]
      subscribers_url : string;
      subscription_url : string;
      svn_url : string;
      tags_url : string;
      teams_url : string;
      temp_clone_token : string option; [@default None]
      template_repository : Template_repository.t option; [@default None]
      topics : Topics.t option; [@default None]
      trees_url : string;
      updated_at : string option;
      url : string;
      visibility : string; [@default "public"]
      watchers : int;
      watchers_count : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Organization_invitation = struct
  module Primary = struct
    type t = {
      created_at : string;
      email : string option;
      failed_at : string option; [@default None]
      failed_reason : string option; [@default None]
      id : int;
      invitation_teams_url : string;
      inviter : Simple_user.t;
      login : string option;
      node_id : string;
      role : string;
      team_count : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Auto_merge = struct
  module Primary = struct
    module Merge_method = struct
      let t_of_yojson = function
        | `String "merge" -> Ok "merge"
        | `String "squash" -> Ok "squash"
        | `String "rebase" -> Ok "rebase"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      commit_message : string;
      commit_title : string;
      enabled_by : Simple_user.t;
      merge_method : Merge_method.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Nullable_scoped_installation = struct
  module Primary = struct
    module Repository_selection = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "selected" -> Ok "selected"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Single_file_paths = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      account : Simple_user.t;
      has_multiple_single_files : bool option; [@default None]
      permissions : App_permissions.t;
      repositories_url : string;
      repository_selection : Repository_selection.t;
      single_file_name : string option;
      single_file_paths : Single_file_paths.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Team_project = struct
  module Primary = struct
    module Permissions = struct
      module Primary = struct
        type t = {
          admin : bool;
          read : bool;
          write : bool;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      body : string option;
      columns_url : string;
      created_at : string;
      creator : Simple_user.t;
      html_url : string;
      id : int;
      name : string;
      node_id : string;
      number : int;
      organization_permission : string option; [@default None]
      owner_url : string;
      permissions : Permissions.t;
      private_ : bool option; [@default None] [@key "private"]
      state : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Nullable_repository = struct
  module Primary = struct
    module Permissions = struct
      module Primary = struct
        type t = {
          admin : bool;
          maintain : bool option; [@default None]
          pull : bool;
          push : bool;
          triage : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Template_repository = struct
      module Primary = struct
        module Owner = struct
          module Primary = struct
            type t = {
              avatar_url : string option; [@default None]
              events_url : string option; [@default None]
              followers_url : string option; [@default None]
              following_url : string option; [@default None]
              gists_url : string option; [@default None]
              gravatar_id : string option; [@default None]
              html_url : string option; [@default None]
              id : int option; [@default None]
              login : string option; [@default None]
              node_id : string option; [@default None]
              organizations_url : string option; [@default None]
              received_events_url : string option; [@default None]
              repos_url : string option; [@default None]
              site_admin : bool option; [@default None]
              starred_url : string option; [@default None]
              subscriptions_url : string option; [@default None]
              type_ : string option; [@default None] [@key "type"]
              url : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Permissions = struct
          module Primary = struct
            type t = {
              admin : bool option; [@default None]
              maintain : bool option; [@default None]
              pull : bool option; [@default None]
              push : bool option; [@default None]
              triage : bool option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Topics = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          allow_auto_merge : bool option; [@default None]
          allow_merge_commit : bool option; [@default None]
          allow_rebase_merge : bool option; [@default None]
          allow_squash_merge : bool option; [@default None]
          archive_url : string option; [@default None]
          archived : bool option; [@default None]
          assignees_url : string option; [@default None]
          blobs_url : string option; [@default None]
          branches_url : string option; [@default None]
          clone_url : string option; [@default None]
          collaborators_url : string option; [@default None]
          comments_url : string option; [@default None]
          commits_url : string option; [@default None]
          compare_url : string option; [@default None]
          contents_url : string option; [@default None]
          contributors_url : string option; [@default None]
          created_at : string option; [@default None]
          default_branch : string option; [@default None]
          delete_branch_on_merge : bool option; [@default None]
          deployments_url : string option; [@default None]
          description : string option; [@default None]
          disabled : bool option; [@default None]
          downloads_url : string option; [@default None]
          events_url : string option; [@default None]
          fork : bool option; [@default None]
          forks_count : int option; [@default None]
          forks_url : string option; [@default None]
          full_name : string option; [@default None]
          git_commits_url : string option; [@default None]
          git_refs_url : string option; [@default None]
          git_tags_url : string option; [@default None]
          git_url : string option; [@default None]
          has_downloads : bool option; [@default None]
          has_issues : bool option; [@default None]
          has_pages : bool option; [@default None]
          has_projects : bool option; [@default None]
          has_wiki : bool option; [@default None]
          homepage : string option; [@default None]
          hooks_url : string option; [@default None]
          html_url : string option; [@default None]
          id : int option; [@default None]
          is_template : bool option; [@default None]
          issue_comment_url : string option; [@default None]
          issue_events_url : string option; [@default None]
          issues_url : string option; [@default None]
          keys_url : string option; [@default None]
          labels_url : string option; [@default None]
          language : string option; [@default None]
          languages_url : string option; [@default None]
          merges_url : string option; [@default None]
          milestones_url : string option; [@default None]
          mirror_url : string option; [@default None]
          name : string option; [@default None]
          network_count : int option; [@default None]
          node_id : string option; [@default None]
          notifications_url : string option; [@default None]
          open_issues_count : int option; [@default None]
          owner : Owner.t option; [@default None]
          permissions : Permissions.t option; [@default None]
          private_ : bool option; [@default None] [@key "private"]
          pulls_url : string option; [@default None]
          pushed_at : string option; [@default None]
          releases_url : string option; [@default None]
          size : int option; [@default None]
          ssh_url : string option; [@default None]
          stargazers_count : int option; [@default None]
          stargazers_url : string option; [@default None]
          statuses_url : string option; [@default None]
          subscribers_count : int option; [@default None]
          subscribers_url : string option; [@default None]
          subscription_url : string option; [@default None]
          svn_url : string option; [@default None]
          tags_url : string option; [@default None]
          teams_url : string option; [@default None]
          temp_clone_token : string option; [@default None]
          topics : Topics.t option; [@default None]
          trees_url : string option; [@default None]
          updated_at : string option; [@default None]
          url : string option; [@default None]
          visibility : string option; [@default None]
          watchers_count : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Topics = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      allow_auto_merge : bool; [@default false]
      allow_forking : bool option; [@default None]
      allow_merge_commit : bool; [@default true]
      allow_rebase_merge : bool; [@default true]
      allow_squash_merge : bool; [@default true]
      archive_url : string;
      archived : bool; [@default false]
      assignees_url : string;
      blobs_url : string;
      branches_url : string;
      clone_url : string;
      collaborators_url : string;
      comments_url : string;
      commits_url : string;
      compare_url : string;
      contents_url : string;
      contributors_url : string;
      created_at : string option;
      default_branch : string;
      delete_branch_on_merge : bool; [@default false]
      deployments_url : string;
      description : string option;
      disabled : bool;
      downloads_url : string;
      events_url : string;
      fork : bool;
      forks : int;
      forks_count : int;
      forks_url : string;
      full_name : string;
      git_commits_url : string;
      git_refs_url : string;
      git_tags_url : string;
      git_url : string;
      has_downloads : bool; [@default true]
      has_issues : bool; [@default true]
      has_pages : bool;
      has_projects : bool; [@default true]
      has_wiki : bool; [@default true]
      homepage : string option;
      hooks_url : string;
      html_url : string;
      id : int;
      is_template : bool; [@default false]
      issue_comment_url : string;
      issue_events_url : string;
      issues_url : string;
      keys_url : string;
      labels_url : string;
      language : string option;
      languages_url : string;
      license : Nullable_license_simple.t option;
      master_branch : string option; [@default None]
      merges_url : string;
      milestones_url : string;
      mirror_url : string option;
      name : string;
      network_count : int option; [@default None]
      node_id : string;
      notifications_url : string;
      open_issues : int;
      open_issues_count : int;
      organization : Nullable_simple_user.t option; [@default None]
      owner : Simple_user.t;
      permissions : Permissions.t option; [@default None]
      private_ : bool; [@default false] [@key "private"]
      pulls_url : string;
      pushed_at : string option;
      releases_url : string;
      size : int;
      ssh_url : string;
      stargazers_count : int;
      stargazers_url : string;
      starred_at : string option; [@default None]
      statuses_url : string;
      subscribers_count : int option; [@default None]
      subscribers_url : string;
      subscription_url : string;
      svn_url : string;
      tags_url : string;
      teams_url : string;
      temp_clone_token : string option; [@default None]
      template_repository : Template_repository.t option; [@default None]
      topics : Topics.t option; [@default None]
      trees_url : string;
      updated_at : string option;
      url : string;
      visibility : string; [@default "public"]
      watchers : int;
      watchers_count : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Base_gist = struct
  module Primary = struct
    module Files = struct
      module Additional = struct
        module Primary = struct
          type t = {
            filename : string option; [@default None]
            language : string option; [@default None]
            raw_url : string option; [@default None]
            size : int option; [@default None]
            type_ : string option; [@default None] [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
    end

    module Forks = struct
      module Items = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module History = struct
      module Items = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      comments : int;
      comments_url : string;
      commits_url : string;
      created_at : string;
      description : string option;
      files : Files.t;
      forks : Forks.t option; [@default None]
      forks_url : string;
      git_pull_url : string;
      git_push_url : string;
      history : History.t option; [@default None]
      html_url : string;
      id : string;
      node_id : string;
      owner : Simple_user.t option; [@default None]
      public : bool;
      truncated : bool option; [@default None]
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Environment_approvals = struct
  module Primary = struct
    module Environments = struct
      module Items = struct
        module Primary = struct
          type t = {
            created_at : string option; [@default None]
            html_url : string option; [@default None]
            id : int option; [@default None]
            name : string option; [@default None]
            node_id : string option; [@default None]
            updated_at : string option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module State = struct
      let t_of_yojson = function
        | `String "approved" -> Ok "approved"
        | `String "rejected" -> Ok "rejected"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      comment : string;
      environments : Environments.t;
      state : State.t;
      user : Simple_user.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Installation = struct
  module Primary = struct
    module Account = struct
      type t =
        | V0 of Simple_user.t
        | V1 of Enterprise.t
      [@@deriving show]

      let of_yojson =
        Json_schema.any_of
          (let open CCResult in
          [
            (fun v -> map (fun v -> V0 v) (Simple_user.of_yojson v));
            (fun v -> map (fun v -> V1 v) (Enterprise.of_yojson v));
          ])

      let to_yojson = function
        | V0 v -> Simple_user.to_yojson v
        | V1 v -> Enterprise.to_yojson v
    end

    module Events = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Repository_selection = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "selected" -> Ok "selected"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Single_file_paths = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      access_tokens_url : string;
      account : Account.t option;
      app_id : int;
      app_slug : string;
      contact_email : string option; [@default None]
      created_at : string;
      events : Events.t;
      has_multiple_single_files : bool option; [@default None]
      html_url : string;
      id : int;
      permissions : App_permissions.t;
      repositories_url : string;
      repository_selection : Repository_selection.t;
      single_file_name : string option;
      single_file_paths : Single_file_paths.t option; [@default None]
      suspended_at : string option;
      suspended_by : Nullable_simple_user.t option;
      target_id : int;
      target_type : string;
      updated_at : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Page = struct
  module Primary = struct
    module Protected_domain_state = struct
      let t_of_yojson = function
        | `String "pending" -> Ok "pending"
        | `String "verified" -> Ok "verified"
        | `String "unverified" -> Ok "unverified"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Status_ = struct
      let t_of_yojson = function
        | `String "built" -> Ok "built"
        | `String "building" -> Ok "building"
        | `String "errored" -> Ok "errored"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      cname : string option;
      custom_404 : bool; [@default false]
      html_url : string option; [@default None]
      https_certificate : Pages_https_certificate.t option; [@default None]
      https_enforced : bool option; [@default None]
      pending_domain_unverified_at : string option; [@default None]
      protected_domain_state : Protected_domain_state.t option; [@default None]
      public : bool;
      source : Pages_source_hash.t option; [@default None]
      status : Status_.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Interaction_limit = struct
  module Primary = struct
    type t = {
      expiry : Interaction_expiry.t option; [@default None]
      limit : Interaction_group.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Pull_request_review_comment = struct
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

        module Self = struct
          module Primary = struct
            type t = { href : string } [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          html : Html.t;
          pull_request : Pull_request_.t;
          self : Self.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Side = struct
      let t_of_yojson = function
        | `String "LEFT" -> Ok "LEFT"
        | `String "RIGHT" -> Ok "RIGHT"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Start_side = struct
      let t_of_yojson = function
        | `String "LEFT" -> Ok "LEFT"
        | `String "RIGHT" -> Ok "RIGHT"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      author_association : Author_association.t;
      body : string;
      body_html : string option; [@default None]
      body_text : string option; [@default None]
      commit_id : string;
      created_at : string;
      diff_hunk : string;
      html_url : string;
      id : int;
      in_reply_to_id : int option; [@default None]
      line : int option; [@default None]
      node_id : string;
      original_commit_id : string;
      original_line : int option; [@default None]
      original_position : int;
      original_start_line : int option; [@default None]
      path : string;
      position : int;
      pull_request_review_id : int option;
      pull_request_url : string;
      reactions : Reaction_rollup.t option; [@default None]
      side : Side.t; [@default "RIGHT"]
      start_line : int option; [@default None]
      start_side : Start_side.t option; [@default Some "RIGHT"]
      updated_at : string;
      url : string;
      user : Simple_user.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Gist_comment = struct
  module Primary = struct
    type t = {
      author_association : Author_association.t;
      body : string;
      created_at : string;
      id : int;
      node_id : string;
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Pull_request_review = struct
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
      author_association : Author_association.t;
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
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Timeline_reviewed_event = struct
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
      author_association : Author_association.t;
      body : string option;
      body_html : string option; [@default None]
      body_text : string option; [@default None]
      commit_id : string;
      event : string;
      html_url : string;
      id : int;
      node_id : string;
      pull_request_url : string;
      state : string;
      submitted_at : string option; [@default None]
      user : Simple_user.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Commit_comment = struct
  module Primary = struct
    type t = {
      author_association : Author_association.t;
      body : string;
      commit_id : string;
      created_at : string;
      html_url : string;
      id : int;
      line : int option;
      node_id : string;
      path : string option;
      position : int option;
      reactions : Reaction_rollup.t option; [@default None]
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Actions_repository_permissions = struct
  module Primary = struct
    type t = {
      allowed_actions : Allowed_actions.t option; [@default None]
      enabled : bool;
      selected_actions_url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Actions_enterprise_permissions = struct
  module Primary = struct
    type t = {
      allowed_actions : Allowed_actions.t option; [@default None]
      enabled_organizations : Enabled_organizations.t;
      selected_actions_url : string option; [@default None]
      selected_organizations_url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Review_comment = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          html : Link.t;
          pull_request : Link.t;
          self : Link.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Side = struct
      let t_of_yojson = function
        | `String "LEFT" -> Ok "LEFT"
        | `String "RIGHT" -> Ok "RIGHT"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Start_side = struct
      let t_of_yojson = function
        | `String "LEFT" -> Ok "LEFT"
        | `String "RIGHT" -> Ok "RIGHT"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      author_association : Author_association.t;
      body : string;
      body_html : string option; [@default None]
      body_text : string option; [@default None]
      commit_id : string;
      created_at : string;
      diff_hunk : string;
      html_url : string;
      id : int;
      in_reply_to_id : int option; [@default None]
      line : int option; [@default None]
      node_id : string;
      original_commit_id : string;
      original_line : int option; [@default None]
      original_position : int;
      original_start_line : int option; [@default None]
      path : string;
      position : int option;
      pull_request_review_id : int option;
      pull_request_url : string;
      reactions : Reaction_rollup.t option; [@default None]
      side : Side.t; [@default "RIGHT"]
      start_line : int option; [@default None]
      start_side : Start_side.t option; [@default Some "RIGHT"]
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Secret_scanning_alert = struct
  module Primary = struct
    type t = {
      created_at : string option; [@default None]
      html_url : string option; [@default None]
      locations_url : string option; [@default None]
      number : int option; [@default None]
      resolution : Secret_scanning_alert_resolution.t option; [@default None]
      resolved_at : string option; [@default None]
      resolved_by : Nullable_simple_user.t option; [@default None]
      secret : string option; [@default None]
      secret_type : string option; [@default None]
      state : Secret_scanning_alert_state.t option; [@default None]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_alert_instance = struct
  module Primary = struct
    module Classifications = struct
      type t = Code_scanning_alert_classification.t list
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Message = struct
      module Primary = struct
        type t = { text : string option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      analysis_key : string option; [@default None]
      category : string option; [@default None]
      classifications : Classifications.t option; [@default None]
      commit_sha : string option; [@default None]
      environment : string option; [@default None]
      html_url : string option; [@default None]
      location : Code_scanning_alert_location.t option; [@default None]
      message : Message.t option; [@default None]
      ref_ : string option; [@default None] [@key "ref"]
      state : Code_scanning_alert_state.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Topic_search_result_item = struct
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
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = { topic_relation : Topic_relation.t option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
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
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = { topic_relation : Topic_relation.t option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      aliases : Aliases.t option; [@default None]
      created_at : string;
      created_by : string option;
      curated : bool;
      description : string option;
      display_name : string option;
      featured : bool;
      logo_url : string option; [@default None]
      name : string;
      related : Related.t option; [@default None]
      released : string option;
      repository_count : int option; [@default None]
      score : float;
      short_description : string option;
      text_matches : Search_result_text_matches.t option; [@default None]
      updated_at : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Repo_search_result_item = struct
  module Primary = struct
    module Permissions = struct
      module Primary = struct
        type t = {
          admin : bool;
          maintain : bool option; [@default None]
          pull : bool;
          push : bool;
          triage : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Topics = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      allow_auto_merge : bool option; [@default None]
      allow_forking : bool option; [@default None]
      allow_merge_commit : bool option; [@default None]
      allow_rebase_merge : bool option; [@default None]
      allow_squash_merge : bool option; [@default None]
      archive_url : string;
      archived : bool;
      assignees_url : string;
      blobs_url : string;
      branches_url : string;
      clone_url : string;
      collaborators_url : string;
      comments_url : string;
      commits_url : string;
      compare_url : string;
      contents_url : string;
      contributors_url : string;
      created_at : string;
      default_branch : string;
      delete_branch_on_merge : bool option; [@default None]
      deployments_url : string;
      description : string option;
      disabled : bool;
      downloads_url : string;
      events_url : string;
      fork : bool;
      forks : int;
      forks_count : int;
      forks_url : string;
      full_name : string;
      git_commits_url : string;
      git_refs_url : string;
      git_tags_url : string;
      git_url : string;
      has_downloads : bool;
      has_issues : bool;
      has_pages : bool;
      has_projects : bool;
      has_wiki : bool;
      homepage : string option;
      hooks_url : string;
      html_url : string;
      id : int;
      is_template : bool option; [@default None]
      issue_comment_url : string;
      issue_events_url : string;
      issues_url : string;
      keys_url : string;
      labels_url : string;
      language : string option;
      languages_url : string;
      license : Nullable_license_simple.t option;
      master_branch : string option; [@default None]
      merges_url : string;
      milestones_url : string;
      mirror_url : string option;
      name : string;
      node_id : string;
      notifications_url : string;
      open_issues : int;
      open_issues_count : int;
      owner : Nullable_simple_user.t option;
      permissions : Permissions.t option; [@default None]
      private_ : bool; [@key "private"]
      pulls_url : string;
      pushed_at : string;
      releases_url : string;
      score : float;
      size : int;
      ssh_url : string;
      stargazers_count : int;
      stargazers_url : string;
      statuses_url : string;
      subscribers_url : string;
      subscription_url : string;
      svn_url : string;
      tags_url : string;
      teams_url : string;
      temp_clone_token : string option; [@default None]
      text_matches : Search_result_text_matches.t option; [@default None]
      topics : Topics.t option; [@default None]
      trees_url : string;
      updated_at : string;
      url : string;
      visibility : string option; [@default None]
      watchers : int;
      watchers_count : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Label_search_result_item = struct
  module Primary = struct
    type t = {
      color : string;
      default : bool;
      description : string option;
      id : int;
      name : string;
      node_id : string;
      score : float;
      text_matches : Search_result_text_matches.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module User_search_result_item = struct
  module Primary = struct
    type t = {
      avatar_url : string;
      bio : string option; [@default None]
      blog : string option; [@default None]
      company : string option; [@default None]
      created_at : string option; [@default None]
      email : string option; [@default None]
      events_url : string;
      followers : int option; [@default None]
      followers_url : string;
      following : int option; [@default None]
      following_url : string;
      gists_url : string;
      gravatar_id : string option;
      hireable : bool option; [@default None]
      html_url : string;
      id : int;
      location : string option; [@default None]
      login : string;
      name : string option; [@default None]
      node_id : string;
      organizations_url : string;
      public_gists : int option; [@default None]
      public_repos : int option; [@default None]
      received_events_url : string;
      repos_url : string;
      score : float;
      site_admin : bool;
      starred_url : string;
      subscriptions_url : string;
      suspended_at : string option; [@default None]
      text_matches : Search_result_text_matches.t option; [@default None]
      type_ : string; [@key "type"]
      updated_at : string option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module View_traffic = struct
  module Primary = struct
    module Views = struct
      type t = Traffic.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      count : int;
      uniques : int;
      views : Views.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Clone_traffic = struct
  module Primary = struct
    module Clones = struct
      type t = Traffic.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      clones : Clones.t;
      count : int;
      uniques : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module User_marketplace_purchase = struct
  module Primary = struct
    type t = {
      account : Marketplace_account.t;
      billing_cycle : string;
      free_trial_ends_on : string option;
      next_billing_date : string option;
      on_free_trial : bool;
      plan : Marketplace_listing_plan.t;
      unit_count : int option;
      updated_at : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Marketplace_purchase = struct
  module Primary = struct
    module Marketplace_pending_change = struct
      module Primary = struct
        type t = {
          effective_date : string option; [@default None]
          id : int option; [@default None]
          is_installed : bool option; [@default None]
          plan : Marketplace_listing_plan.t option; [@default None]
          unit_count : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Marketplace_purchase_ = struct
      module Primary = struct
        type t = {
          billing_cycle : string option; [@default None]
          free_trial_ends_on : string option; [@default None]
          is_installed : bool option; [@default None]
          next_billing_date : string option; [@default None]
          on_free_trial : bool option; [@default None]
          plan : Marketplace_listing_plan.t option; [@default None]
          unit_count : int option; [@default None]
          updated_at : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      email : string option; [@default None]
      id : int;
      login : string;
      marketplace_pending_change : Marketplace_pending_change.t option; [@default None]
      marketplace_purchase : Marketplace_purchase_.t;
      organization_billing_email : string option; [@default None]
      type_ : string; [@key "type"]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Release = struct
  module Primary = struct
    module Assets = struct
      type t = Release_asset.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      assets : Assets.t;
      assets_url : string;
      author : Simple_user.t;
      body : string option; [@default None]
      body_html : string option; [@default None]
      body_text : string option; [@default None]
      created_at : string;
      discussion_url : string option; [@default None]
      draft : bool;
      html_url : string;
      id : int;
      mentions_count : int option; [@default None]
      name : string option;
      node_id : string;
      prerelease : bool;
      published_at : string option;
      reactions : Reaction_rollup.t option; [@default None]
      tag_name : string;
      tarball_url : string option;
      target_commitish : string;
      upload_url : string;
      url : string;
      zipball_url : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Assigned_issue_event = struct
  module Primary = struct
    type t = {
      actor : Simple_user.t;
      assignee : Simple_user.t;
      assigner : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Integration.t;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Converted_note_to_issue_issue_event = struct
  module Primary = struct
    module Project_card_ = struct
      module Primary = struct
        type t = {
          column_name : string;
          id : int;
          previous_column_name : string option; [@default None]
          project_id : int;
          project_url : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Integration.t;
      project_card : Project_card_.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Deployment_simple = struct
  module Primary = struct
    type t = {
      created_at : string;
      description : string option;
      environment : string;
      id : int;
      node_id : string;
      original_environment : string option; [@default None]
      performed_via_github_app : Nullable_integration.t option; [@default None]
      production_environment : bool option; [@default None]
      repository_url : string;
      statuses_url : string;
      task : string;
      transient_environment : bool option; [@default None]
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Labeled_issue_event = struct
  module Primary = struct
    module Label_ = struct
      module Primary = struct
        type t = {
          color : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      label : Label_.t;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Timeline_comment_event = struct
  module Primary = struct
    type t = {
      actor : Simple_user.t;
      author_association : Author_association.t;
      body : string option; [@default None]
      body_html : string option; [@default None]
      body_text : string option; [@default None]
      created_at : string;
      event : string;
      html_url : string;
      id : int;
      issue_url : string;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option; [@default None]
      reactions : Reaction_rollup.t option; [@default None]
      updated_at : string;
      url : string;
      user : Simple_user.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Timeline_unassigned_issue_event = struct
  module Primary = struct
    type t = {
      actor : Simple_user.t;
      assignee : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Deployment = struct
  module Primary = struct
    module Payload = struct
      module V0 = struct
        include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
      end

      module V1 = struct
        type t = string [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t =
        | V0 of V0.t
        | V1 of V1.t
      [@@deriving show]

      let of_yojson =
        Json_schema.one_of
          (let open CCResult in
          [
            (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
            (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
          ])

      let to_yojson = function
        | V0 v -> V0.to_yojson v
        | V1 v -> V1.to_yojson v
    end

    type t = {
      created_at : string;
      creator : Nullable_simple_user.t option;
      description : string option;
      environment : string;
      id : int;
      node_id : string;
      original_environment : string option; [@default None]
      payload : Payload.t;
      performed_via_github_app : Nullable_integration.t option; [@default None]
      production_environment : bool option; [@default None]
      ref_ : string; [@key "ref"]
      repository_url : string;
      sha : string;
      statuses_url : string;
      task : string;
      transient_environment : bool option; [@default None]
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Unlabeled_issue_event = struct
  module Primary = struct
    module Label_ = struct
      module Primary = struct
        type t = {
          color : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      label : Label_.t;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Demilestoned_issue_event = struct
  module Primary = struct
    module Milestone_ = struct
      module Primary = struct
        type t = { title : string } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      milestone : Milestone_.t;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Review_dismissed_issue_event = struct
  module Primary = struct
    module Dismissed_review = struct
      module Primary = struct
        type t = {
          dismissal_commit_id : string option; [@default None]
          dismissal_message : string option;
          review_id : int;
          state : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      dismissed_review : Dismissed_review.t;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Locked_issue_event = struct
  module Primary = struct
    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      lock_reason : string option;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Milestoned_issue_event = struct
  module Primary = struct
    module Milestone_ = struct
      module Primary = struct
        type t = { title : string } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      milestone : Milestone_.t;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Timeline_assigned_issue_event = struct
  module Primary = struct
    type t = {
      actor : Simple_user.t;
      assignee : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Issue_comment = struct
  module Primary = struct
    type t = {
      author_association : Author_association.t;
      body : string option; [@default None]
      body_html : string option; [@default None]
      body_text : string option; [@default None]
      created_at : string;
      html_url : string;
      id : int;
      issue_url : string;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option; [@default None]
      reactions : Reaction_rollup.t option; [@default None]
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Moved_column_in_project_issue_event = struct
  module Primary = struct
    module Project_card_ = struct
      module Primary = struct
        type t = {
          column_name : string;
          id : int;
          previous_column_name : string option; [@default None]
          project_id : int;
          project_url : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      project_card : Project_card_.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Unassigned_issue_event = struct
  module Primary = struct
    type t = {
      actor : Simple_user.t;
      assignee : Simple_user.t;
      assigner : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Deployment_status = struct
  module Primary = struct
    module State = struct
      let t_of_yojson = function
        | `String "error" -> Ok "error"
        | `String "failure" -> Ok "failure"
        | `String "inactive" -> Ok "inactive"
        | `String "pending" -> Ok "pending"
        | `String "success" -> Ok "success"
        | `String "queued" -> Ok "queued"
        | `String "in_progress" -> Ok "in_progress"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      created_at : string;
      creator : Nullable_simple_user.t option;
      deployment_url : string;
      description : string; [@default ""]
      environment : string; [@default ""]
      environment_url : string; [@default ""]
      id : int;
      log_url : string; [@default ""]
      node_id : string;
      performed_via_github_app : Nullable_integration.t option; [@default None]
      repository_url : string;
      state : State.t;
      target_url : string; [@default ""]
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Renamed_issue_event = struct
  module Primary = struct
    module Rename = struct
      module Primary = struct
        type t = {
          from : string;
          to_ : string; [@key "to"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      rename : Rename.t;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Added_to_project_issue_event = struct
  module Primary = struct
    module Project_card_ = struct
      module Primary = struct
        type t = {
          column_name : string;
          id : int;
          previous_column_name : string option; [@default None]
          project_id : int;
          project_url : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      project_card : Project_card_.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Removed_from_project_issue_event = struct
  module Primary = struct
    module Project_card_ = struct
      module Primary = struct
        type t = {
          column_name : string;
          id : int;
          previous_column_name : string option; [@default None]
          project_id : int;
          project_url : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      project_card : Project_card_.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Gist_simple = struct
  module Primary = struct
    module Files = struct
      module Additional = struct
        module Primary = struct
          type t = {
            content : string option; [@default None]
            filename : string option; [@default None]
            language : string option; [@default None]
            raw_url : string option; [@default None]
            size : int option; [@default None]
            truncated : bool option; [@default None]
            type_ : string option; [@default None] [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
    end

    module Fork_of = struct
      module Primary = struct
        module Files = struct
          module Additional = struct
            module Primary = struct
              type t = {
                filename : string option; [@default None]
                language : string option; [@default None]
                raw_url : string option; [@default None]
                size : int option; [@default None]
                type_ : string option; [@default None] [@key "type"]
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
        end

        module Forks = struct
          module Items = struct
            type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
        end

        module History = struct
          module Items = struct
            type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          comments : int;
          comments_url : string;
          commits_url : string;
          created_at : string;
          description : string option;
          files : Files.t;
          forks : Forks.t option; [@default None]
          forks_url : string;
          git_pull_url : string;
          git_push_url : string;
          history : History.t option; [@default None]
          html_url : string;
          id : string;
          node_id : string;
          owner : Nullable_simple_user.t option; [@default None]
          public : bool;
          truncated : bool option; [@default None]
          updated_at : string;
          url : string;
          user : Nullable_simple_user.t option;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Forks = struct
      module Items = struct
        module Primary = struct
          type t = {
            created_at : string option; [@default None]
            id : string option; [@default None]
            updated_at : string option; [@default None]
            url : string option; [@default None]
            user : Public_user.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module History = struct
      type t = Gist_history.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      comments : int option; [@default None]
      comments_url : string option; [@default None]
      commits_url : string option; [@default None]
      created_at : string option; [@default None]
      description : string option; [@default None]
      files : Files.t option; [@default None]
      fork_of : Fork_of.t option; [@default None]
      forks : Forks.t option; [@default None]
      forks_url : string option; [@default None]
      git_pull_url : string option; [@default None]
      git_push_url : string option; [@default None]
      history : History.t option; [@default None]
      html_url : string option; [@default None]
      id : string option; [@default None]
      node_id : string option; [@default None]
      owner : Simple_user.t option; [@default None]
      public : bool option; [@default None]
      truncated : bool option; [@default None]
      updated_at : string option; [@default None]
      url : string option; [@default None]
      user : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Pull_request_review_request = struct
  module Primary = struct
    module Teams = struct
      type t = Team.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Users = struct
      type t = Simple_user.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      teams : Teams.t;
      users : Users.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Review_requested_issue_event = struct
  module Primary = struct
    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      requested_reviewer : Simple_user.t option; [@default None]
      requested_team : Team.t option; [@default None]
      review_requester : Simple_user.t;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Review_request_removed_issue_event = struct
  module Primary = struct
    type t = {
      actor : Simple_user.t;
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      event : string;
      id : int;
      node_id : string;
      performed_via_github_app : Nullable_integration.t option;
      requested_reviewer : Simple_user.t option; [@default None]
      requested_team : Team.t option; [@default None]
      review_requester : Simple_user.t;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Environment = struct
  module Primary = struct
    module Protection_rules = struct
      module Items = struct
        module V0 = struct
          module Primary = struct
            type t = {
              id : int;
              node_id : string;
              type_ : string; [@key "type"]
              wait_timer : int option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module V1 = struct
          module Primary = struct
            module Reviewers = struct
              module Items = struct
                module Primary = struct
                  module Reviewer = struct
                    type t =
                      | V0 of Simple_user.t
                      | V1 of Team.t
                    [@@deriving show]

                    let of_yojson =
                      Json_schema.any_of
                        (let open CCResult in
                        [
                          (fun v -> map (fun v -> V0 v) (Simple_user.of_yojson v));
                          (fun v -> map (fun v -> V1 v) (Team.of_yojson v));
                        ])

                    let to_yojson = function
                      | V0 v -> Simple_user.to_yojson v
                      | V1 v -> Team.to_yojson v
                  end

                  type t = {
                    reviewer : Reviewer.t option; [@default None]
                    type_ : Deployment_reviewer_type.t option; [@default None] [@key "type"]
                  }
                  [@@deriving yojson { strict = false; meta = true }, show]
                end

                include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
              end

              type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = {
              id : int;
              node_id : string;
              reviewers : Reviewers.t option; [@default None]
              type_ : string; [@key "type"]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module V2 = struct
          module Primary = struct
            type t = {
              id : int;
              node_id : string;
              type_ : string; [@key "type"]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t =
          | V0 of V0.t
          | V1 of V1.t
          | V2 of V2.t
        [@@deriving show]

        let of_yojson =
          Json_schema.any_of
            (let open CCResult in
            [
              (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
              (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
              (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
            ])

        let to_yojson = function
          | V0 v -> V0.to_yojson v
          | V1 v -> V1.to_yojson v
          | V2 v -> V2.to_yojson v
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      created_at : string;
      deployment_branch_policy : Deployment_branch_policy.t option; [@default None]
      html_url : string;
      id : int;
      name : string;
      node_id : string;
      protection_rules : Protection_rules.t option; [@default None]
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Protected_branch = struct
  module Primary = struct
    module Allow_deletions = struct
      type t = { enabled : bool } [@@deriving yojson { strict = true; meta = true }, show]
    end

    module Allow_force_pushes = struct
      type t = { enabled : bool } [@@deriving yojson { strict = true; meta = true }, show]
    end

    module Enforce_admins = struct
      type t = {
        enabled : bool;
        url : string;
      }
      [@@deriving yojson { strict = true; meta = true }, show]
    end

    module Required_conversation_resolution = struct
      type t = { enabled : bool option [@default None] }
      [@@deriving yojson { strict = true; meta = true }, show]
    end

    module Required_linear_history = struct
      type t = { enabled : bool } [@@deriving yojson { strict = true; meta = true }, show]
    end

    module Required_pull_request_reviews = struct
      module Primary = struct
        module Dismissal_restrictions = struct
          module Primary = struct
            module Teams = struct
              type t = Team.t list [@@deriving yojson { strict = false; meta = true }, show]
            end

            module Users = struct
              type t = Simple_user.t list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = {
              teams : Teams.t;
              teams_url : string;
              url : string;
              users : Users.t;
              users_url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          dismiss_stale_reviews : bool option; [@default None]
          dismissal_restrictions : Dismissal_restrictions.t option; [@default None]
          require_code_owner_reviews : bool option; [@default None]
          required_approving_review_count : int option; [@default None]
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Required_signatures = struct
      module Primary = struct
        type t = {
          enabled : bool;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      allow_deletions : Allow_deletions.t option; [@default None]
      allow_force_pushes : Allow_force_pushes.t option; [@default None]
      enforce_admins : Enforce_admins.t option; [@default None]
      required_conversation_resolution : Required_conversation_resolution.t option; [@default None]
      required_linear_history : Required_linear_history.t option; [@default None]
      required_pull_request_reviews : Required_pull_request_reviews.t option; [@default None]
      required_signatures : Required_signatures.t option; [@default None]
      required_status_checks : Status_check_policy.t option; [@default None]
      restrictions : Branch_restriction_policy.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Pending_deployment = struct
  module Primary = struct
    module Environment_ = struct
      module Primary = struct
        type t = {
          html_url : string option; [@default None]
          id : int option; [@default None]
          name : string option; [@default None]
          node_id : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Reviewers = struct
      module Items = struct
        module Primary = struct
          module Reviewer = struct
            type t =
              | V0 of Simple_user.t
              | V1 of Team.t
            [@@deriving show]

            let of_yojson =
              Json_schema.any_of
                (let open CCResult in
                [
                  (fun v -> map (fun v -> V0 v) (Simple_user.of_yojson v));
                  (fun v -> map (fun v -> V1 v) (Team.of_yojson v));
                ])

            let to_yojson = function
              | V0 v -> Simple_user.to_yojson v
              | V1 v -> Team.to_yojson v
          end

          type t = {
            reviewer : Reviewer.t option; [@default None]
            type_ : Deployment_reviewer_type.t option; [@default None] [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      current_user_can_approve : bool;
      environment : Environment_.t;
      reviewers : Reviewers.t;
      wait_timer : int;
      wait_timer_started_at : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Protected_branch_pull_request_review = struct
  module Primary = struct
    module Dismissal_restrictions = struct
      module Primary = struct
        module Teams = struct
          type t = Team.t list [@@deriving yojson { strict = false; meta = true }, show]
        end

        module Users = struct
          type t = Simple_user.t list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          teams : Teams.t option; [@default None]
          teams_url : string option; [@default None]
          url : string option; [@default None]
          users : Users.t option; [@default None]
          users_url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      dismiss_stale_reviews : bool;
      dismissal_restrictions : Dismissal_restrictions.t option; [@default None]
      require_code_owner_reviews : bool;
      required_approving_review_count : int option; [@default None]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_analysis = struct
  module Primary = struct
    type t = {
      analysis_key : string;
      category : string option; [@default None]
      commit_sha : string;
      created_at : string;
      deletable : bool;
      environment : string;
      error : string;
      id : int;
      ref_ : string; [@key "ref"]
      results_count : int;
      rules_count : int;
      sarif_id : string;
      tool : Code_scanning_analysis_tool.t;
      url : string;
      warning : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Commit_comparison = struct
  module Primary = struct
    module Commits = struct
      type t = Commit.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Files = struct
      type t = Diff_entry.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Status_ = struct
      let t_of_yojson = function
        | `String "diverged" -> Ok "diverged"
        | `String "ahead" -> Ok "ahead"
        | `String "behind" -> Ok "behind"
        | `String "identical" -> Ok "identical"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      ahead_by : int;
      base_commit : Commit.t;
      behind_by : int;
      commits : Commits.t;
      diff_url : string;
      files : Files.t option; [@default None]
      html_url : string;
      merge_base_commit : Commit.t;
      patch_url : string;
      permalink_url : string;
      status : Status_.t;
      total_commits : int;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Installation_token = struct
  module Primary = struct
    module Repositories = struct
      type t = Repository.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Repository_selection = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "selected" -> Ok "selected"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Single_file_paths = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      expires_at : string;
      has_multiple_single_files : bool option; [@default None]
      permissions : App_permissions.t option; [@default None]
      repositories : Repositories.t option; [@default None]
      repository_selection : Repository_selection.t option; [@default None]
      single_file : string option; [@default None]
      single_file_paths : Single_file_paths.t option; [@default None]
      token : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Issue_search_result_item = struct
  module Primary = struct
    module Assignees = struct
      type t = Simple_user.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Labels = struct
      module Items = struct
        module Primary = struct
          type t = {
            color : string option; [@default None]
            default : bool option; [@default None]
            description : string option; [@default None]
            id : int64 option; [@default None]
            name : string option; [@default None]
            node_id : string option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Pull_request_ = struct
      module Primary = struct
        type t = {
          diff_url : string option;
          html_url : string option;
          merged_at : string option; [@default None]
          patch_url : string option;
          url : string option;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      active_lock_reason : string option; [@default None]
      assignee : Nullable_simple_user.t option;
      assignees : Assignees.t option; [@default None]
      author_association : Author_association.t;
      body : string option; [@default None]
      body_html : string option; [@default None]
      body_text : string option; [@default None]
      closed_at : string option;
      comments : int;
      comments_url : string;
      created_at : string;
      draft : bool option; [@default None]
      events_url : string;
      html_url : string;
      id : int;
      labels : Labels.t;
      labels_url : string;
      locked : bool;
      milestone : Nullable_milestone.t option;
      node_id : string;
      number : int;
      performed_via_github_app : Nullable_integration.t option; [@default None]
      pull_request : Pull_request_.t option; [@default None]
      reactions : Reaction_rollup.t option; [@default None]
      repository : Repository.t option; [@default None]
      repository_url : string;
      score : float;
      state : string;
      text_matches : Search_result_text_matches.t option; [@default None]
      timeline_url : string option; [@default None]
      title : string;
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Authentication_token = struct
  module Primary = struct
    module Permissions = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    module Repositories = struct
      type t = Repository.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Repository_selection = struct
      let t_of_yojson = function
        | `String "all" -> Ok "all"
        | `String "selected" -> Ok "selected"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      expires_at : string;
      permissions : Permissions.t option; [@default None]
      repositories : Repositories.t option; [@default None]
      repository_selection : Repository_selection.t option; [@default None]
      single_file : string option; [@default None]
      token : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Issue = struct
  module Primary = struct
    module Assignees = struct
      type t = Simple_user.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Labels = struct
      module Items = struct
        module V0 = struct
          type t = string [@@deriving yojson { strict = false; meta = true }, show]
        end

        module V1 = struct
          module Primary = struct
            type t = {
              color : string option; [@default None]
              default : bool option; [@default None]
              description : string option; [@default None]
              id : int64 option; [@default None]
              name : string option; [@default None]
              node_id : string option; [@default None]
              url : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t =
          | V0 of V0.t
          | V1 of V1.t
        [@@deriving show]

        let of_yojson =
          Json_schema.one_of
            (let open CCResult in
            [
              (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
              (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
            ])

        let to_yojson = function
          | V0 v -> V0.to_yojson v
          | V1 v -> V1.to_yojson v
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Pull_request_ = struct
      module Primary = struct
        type t = {
          diff_url : string option;
          html_url : string option;
          merged_at : string option; [@default None]
          patch_url : string option;
          url : string option;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      active_lock_reason : string option; [@default None]
      assignee : Nullable_simple_user.t option;
      assignees : Assignees.t option; [@default None]
      author_association : Author_association.t;
      body : string option; [@default None]
      body_html : string option; [@default None]
      body_text : string option; [@default None]
      closed_at : string option;
      closed_by : Nullable_simple_user.t option; [@default None]
      comments : int;
      comments_url : string;
      created_at : string;
      events_url : string;
      html_url : string;
      id : int;
      labels : Labels.t;
      labels_url : string;
      locked : bool;
      milestone : Nullable_milestone.t option;
      node_id : string;
      number : int;
      performed_via_github_app : Nullable_integration.t option; [@default None]
      pull_request : Pull_request_.t option; [@default None]
      reactions : Reaction_rollup.t option; [@default None]
      repository : Repository.t option; [@default None]
      repository_url : string;
      state : string;
      timeline_url : string option; [@default None]
      title : string;
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Migration = struct
  module Primary = struct
    module Exclude = struct
      module Items = struct
        type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Repositories = struct
      type t = Repository.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      archive_url : string option; [@default None]
      created_at : string;
      exclude : Exclude.t option; [@default None]
      exclude_attachments : bool;
      exclude_git_data : bool;
      exclude_metadata : bool;
      exclude_owner_projects : bool;
      exclude_releases : bool;
      guid : string;
      id : int;
      lock_repositories : bool;
      node_id : string;
      owner : Nullable_simple_user.t option;
      repositories : Repositories.t;
      state : string;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Starred_repository = struct
  module Primary = struct
    type t = {
      repo : Repository.t;
      starred_at : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Pull_request = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          comments : Link.t;
          commits : Link.t;
          html : Link.t;
          issue : Link.t;
          review_comment : Link.t;
          review_comments : Link.t;
          self : Link.t;
          statuses : Link.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Assignees = struct
      type t = Simple_user.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Base = struct
      module Primary = struct
        module Repo = struct
          module Primary = struct
            module Owner = struct
              module Primary = struct
                type t = {
                  avatar_url : string;
                  events_url : string;
                  followers_url : string;
                  following_url : string;
                  gists_url : string;
                  gravatar_id : string option;
                  html_url : string;
                  id : int;
                  login : string;
                  node_id : string;
                  organizations_url : string;
                  received_events_url : string;
                  repos_url : string;
                  site_admin : bool;
                  starred_url : string;
                  subscriptions_url : string;
                  type_ : string; [@key "type"]
                  url : string;
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module Permissions = struct
              module Primary = struct
                type t = {
                  admin : bool;
                  maintain : bool option; [@default None]
                  pull : bool;
                  push : bool;
                  triage : bool option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module Topics = struct
              type t = string list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = {
              allow_forking : bool option; [@default None]
              allow_merge_commit : bool option; [@default None]
              allow_rebase_merge : bool option; [@default None]
              allow_squash_merge : bool option; [@default None]
              archive_url : string;
              archived : bool;
              assignees_url : string;
              blobs_url : string;
              branches_url : string;
              clone_url : string;
              collaborators_url : string;
              comments_url : string;
              commits_url : string;
              compare_url : string;
              contents_url : string;
              contributors_url : string;
              created_at : string;
              default_branch : string;
              deployments_url : string;
              description : string option;
              disabled : bool;
              downloads_url : string;
              events_url : string;
              fork : bool;
              forks : int;
              forks_count : int;
              forks_url : string;
              full_name : string;
              git_commits_url : string;
              git_refs_url : string;
              git_tags_url : string;
              git_url : string;
              has_downloads : bool;
              has_issues : bool;
              has_pages : bool;
              has_projects : bool;
              has_wiki : bool;
              homepage : string option;
              hooks_url : string;
              html_url : string;
              id : int;
              is_template : bool option; [@default None]
              issue_comment_url : string;
              issue_events_url : string;
              issues_url : string;
              keys_url : string;
              labels_url : string;
              language : string option;
              languages_url : string;
              license : Nullable_license_simple.t option;
              master_branch : string option; [@default None]
              merges_url : string;
              milestones_url : string;
              mirror_url : string option;
              name : string;
              node_id : string;
              notifications_url : string;
              open_issues : int;
              open_issues_count : int;
              owner : Owner.t;
              permissions : Permissions.t option; [@default None]
              private_ : bool; [@key "private"]
              pulls_url : string;
              pushed_at : string;
              releases_url : string;
              size : int;
              ssh_url : string;
              stargazers_count : int;
              stargazers_url : string;
              statuses_url : string;
              subscribers_url : string;
              subscription_url : string;
              svn_url : string;
              tags_url : string;
              teams_url : string;
              temp_clone_token : string option; [@default None]
              topics : Topics.t option; [@default None]
              trees_url : string;
              updated_at : string;
              url : string;
              visibility : string option; [@default None]
              watchers : int;
              watchers_count : int;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module User = struct
          module Primary = struct
            type t = {
              avatar_url : string;
              events_url : string;
              followers_url : string;
              following_url : string;
              gists_url : string;
              gravatar_id : string option;
              html_url : string;
              id : int;
              login : string;
              node_id : string;
              organizations_url : string;
              received_events_url : string;
              repos_url : string;
              site_admin : bool;
              starred_url : string;
              subscriptions_url : string;
              type_ : string; [@key "type"]
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          label : string;
          ref_ : string; [@key "ref"]
          repo : Repo.t;
          sha : string;
          user : User.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Head = struct
      module Primary = struct
        module Repo = struct
          module Primary = struct
            module License_ = struct
              module Primary = struct
                type t = {
                  key : string;
                  name : string;
                  node_id : string;
                  spdx_id : string option;
                  url : string option;
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module Owner = struct
              module Primary = struct
                type t = {
                  avatar_url : string;
                  events_url : string;
                  followers_url : string;
                  following_url : string;
                  gists_url : string;
                  gravatar_id : string option;
                  html_url : string;
                  id : int;
                  login : string;
                  node_id : string;
                  organizations_url : string;
                  received_events_url : string;
                  repos_url : string;
                  site_admin : bool;
                  starred_url : string;
                  subscriptions_url : string;
                  type_ : string; [@key "type"]
                  url : string;
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module Permissions = struct
              module Primary = struct
                type t = {
                  admin : bool;
                  maintain : bool option; [@default None]
                  pull : bool;
                  push : bool;
                  triage : bool option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            module Topics = struct
              type t = string list [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = {
              allow_forking : bool option; [@default None]
              allow_merge_commit : bool option; [@default None]
              allow_rebase_merge : bool option; [@default None]
              allow_squash_merge : bool option; [@default None]
              archive_url : string;
              archived : bool;
              assignees_url : string;
              blobs_url : string;
              branches_url : string;
              clone_url : string;
              collaborators_url : string;
              comments_url : string;
              commits_url : string;
              compare_url : string;
              contents_url : string;
              contributors_url : string;
              created_at : string;
              default_branch : string;
              deployments_url : string;
              description : string option;
              disabled : bool;
              downloads_url : string;
              events_url : string;
              fork : bool;
              forks : int;
              forks_count : int;
              forks_url : string;
              full_name : string;
              git_commits_url : string;
              git_refs_url : string;
              git_tags_url : string;
              git_url : string;
              has_downloads : bool;
              has_issues : bool;
              has_pages : bool;
              has_projects : bool;
              has_wiki : bool;
              homepage : string option;
              hooks_url : string;
              html_url : string;
              id : int;
              is_template : bool option; [@default None]
              issue_comment_url : string;
              issue_events_url : string;
              issues_url : string;
              keys_url : string;
              labels_url : string;
              language : string option;
              languages_url : string;
              license : License_.t option;
              master_branch : string option; [@default None]
              merges_url : string;
              milestones_url : string;
              mirror_url : string option;
              name : string;
              node_id : string;
              notifications_url : string;
              open_issues : int;
              open_issues_count : int;
              owner : Owner.t;
              permissions : Permissions.t option; [@default None]
              private_ : bool; [@key "private"]
              pulls_url : string;
              pushed_at : string;
              releases_url : string;
              size : int;
              ssh_url : string;
              stargazers_count : int;
              stargazers_url : string;
              statuses_url : string;
              subscribers_url : string;
              subscription_url : string;
              svn_url : string;
              tags_url : string;
              teams_url : string;
              temp_clone_token : string option; [@default None]
              topics : Topics.t option; [@default None]
              trees_url : string;
              updated_at : string;
              url : string;
              visibility : string option; [@default None]
              watchers : int;
              watchers_count : int;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module User = struct
          module Primary = struct
            type t = {
              avatar_url : string;
              events_url : string;
              followers_url : string;
              following_url : string;
              gists_url : string;
              gravatar_id : string option;
              html_url : string;
              id : int;
              login : string;
              node_id : string;
              organizations_url : string;
              received_events_url : string;
              repos_url : string;
              site_admin : bool;
              starred_url : string;
              subscriptions_url : string;
              type_ : string; [@key "type"]
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          label : string;
          ref_ : string; [@key "ref"]
          repo : Repo.t option;
          sha : string;
          user : User.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Labels = struct
      module Items = struct
        module Primary = struct
          type t = {
            color : string option; [@default None]
            default : bool option; [@default None]
            description : string option; [@default None]
            id : int64 option; [@default None]
            name : string option; [@default None]
            node_id : string option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Requested_reviewers = struct
      type t = Simple_user.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Requested_teams = struct
      type t = Team_simple.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module State = struct
      let t_of_yojson = function
        | `String "open" -> Ok "open"
        | `String "closed" -> Ok "closed"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      active_lock_reason : string option; [@default None]
      additions : int;
      assignee : Nullable_simple_user.t option;
      assignees : Assignees.t option; [@default None]
      author_association : Author_association.t;
      auto_merge : Auto_merge.t option;
      base : Base.t;
      body : string option;
      changed_files : int;
      closed_at : string option;
      comments : int;
      comments_url : string;
      commits : int;
      commits_url : string;
      created_at : string;
      deletions : int;
      diff_url : string;
      draft : bool option; [@default None]
      head : Head.t;
      html_url : string;
      id : int;
      issue_url : string;
      labels : Labels.t;
      locked : bool;
      maintainer_can_modify : bool;
      merge_commit_sha : string option;
      mergeable : bool option;
      mergeable_state : string;
      merged : bool;
      merged_at : string option;
      merged_by : Nullable_simple_user.t option;
      milestone : Nullable_milestone.t option;
      node_id : string;
      number : int;
      patch_url : string;
      rebaseable : bool option; [@default None]
      requested_reviewers : Requested_reviewers.t option; [@default None]
      requested_teams : Requested_teams.t option; [@default None]
      review_comment_url : string;
      review_comments : int;
      review_comments_url : string;
      state : State.t;
      statuses_url : string;
      title : string;
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Pull_request_simple = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          comments : Link.t;
          commits : Link.t;
          html : Link.t;
          issue : Link.t;
          review_comment : Link.t;
          review_comments : Link.t;
          self : Link.t;
          statuses : Link.t;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Assignees = struct
      type t = Simple_user.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Base = struct
      module Primary = struct
        type t = {
          label : string;
          ref_ : string; [@key "ref"]
          repo : Repository.t;
          sha : string;
          user : Nullable_simple_user.t option;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Head = struct
      module Primary = struct
        type t = {
          label : string;
          ref_ : string; [@key "ref"]
          repo : Repository.t;
          sha : string;
          user : Nullable_simple_user.t option;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Labels = struct
      module Items = struct
        module Primary = struct
          type t = {
            color : string option; [@default None]
            default : bool option; [@default None]
            description : string option; [@default None]
            id : int64 option; [@default None]
            name : string option; [@default None]
            node_id : string option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Requested_reviewers = struct
      type t = Simple_user.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Requested_teams = struct
      type t = Team.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      active_lock_reason : string option; [@default None]
      assignee : Nullable_simple_user.t option;
      assignees : Assignees.t option; [@default None]
      author_association : Author_association.t;
      auto_merge : Auto_merge.t option;
      base : Base.t;
      body : string option;
      closed_at : string option;
      comments_url : string;
      commits_url : string;
      created_at : string;
      diff_url : string;
      draft : bool option; [@default None]
      head : Head.t;
      html_url : string;
      id : int;
      issue_url : string;
      labels : Labels.t;
      locked : bool;
      merge_commit_sha : string option;
      merged_at : string option;
      milestone : Nullable_milestone.t option;
      node_id : string;
      number : int;
      patch_url : string;
      requested_reviewers : Requested_reviewers.t option; [@default None]
      requested_teams : Requested_teams.t option; [@default None]
      review_comment_url : string;
      review_comments_url : string;
      state : string;
      statuses_url : string;
      title : string;
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Authorization = struct
  module Primary = struct
    module App = struct
      module Primary = struct
        type t = {
          client_id : string;
          name : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Scopes = struct
      type t = string list option [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      app : App.t;
      created_at : string;
      expires_at : string option;
      fingerprint : string option;
      hashed_token : string option;
      id : int;
      installation : Nullable_scoped_installation.t option; [@default None]
      note : string option;
      note_url : string option;
      scopes : Scopes.t option;
      token : string;
      token_last_eight : string option;
      updated_at : string;
      url : string;
      user : Nullable_simple_user.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Full_repository = struct
  module Primary = struct
    module Permissions = struct
      module Primary = struct
        type t = {
          admin : bool;
          maintain : bool option; [@default None]
          pull : bool;
          push : bool;
          triage : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Security_and_analysis = struct
      module Primary = struct
        module Advanced_security = struct
          module Primary = struct
            module Status_ = struct
              let t_of_yojson = function
                | `String "enabled" -> Ok "enabled"
                | `String "disabled" -> Ok "disabled"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = { status : Status_.t option [@default None] }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Secret_scanning = struct
          module Primary = struct
            module Status_ = struct
              let t_of_yojson = function
                | `String "enabled" -> Ok "enabled"
                | `String "disabled" -> Ok "disabled"
                | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

              type t = (string[@of_yojson t_of_yojson])
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            type t = { status : Status_.t option [@default None] }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          advanced_security : Advanced_security.t option; [@default None]
          secret_scanning : Secret_scanning.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Topics = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      allow_auto_merge : bool option; [@default None]
      allow_forking : bool option; [@default None]
      allow_merge_commit : bool option; [@default None]
      allow_rebase_merge : bool option; [@default None]
      allow_squash_merge : bool option; [@default None]
      anonymous_access_enabled : bool; [@default true]
      archive_url : string;
      archived : bool;
      assignees_url : string;
      blobs_url : string;
      branches_url : string;
      clone_url : string;
      code_of_conduct : Code_of_conduct_simple.t option; [@default None]
      collaborators_url : string;
      comments_url : string;
      commits_url : string;
      compare_url : string;
      contents_url : string;
      contributors_url : string;
      created_at : string;
      default_branch : string;
      delete_branch_on_merge : bool option; [@default None]
      deployments_url : string;
      description : string option;
      disabled : bool;
      downloads_url : string;
      events_url : string;
      fork : bool;
      forks : int;
      forks_count : int;
      forks_url : string;
      full_name : string;
      git_commits_url : string;
      git_refs_url : string;
      git_tags_url : string;
      git_url : string;
      has_downloads : bool;
      has_issues : bool;
      has_pages : bool;
      has_projects : bool;
      has_wiki : bool;
      homepage : string option;
      hooks_url : string;
      html_url : string;
      id : int;
      is_template : bool option; [@default None]
      issue_comment_url : string;
      issue_events_url : string;
      issues_url : string;
      keys_url : string;
      labels_url : string;
      language : string option;
      languages_url : string;
      license : Nullable_license_simple.t option;
      master_branch : string option; [@default None]
      merges_url : string;
      milestones_url : string;
      mirror_url : string option;
      name : string;
      network_count : int;
      node_id : string;
      notifications_url : string;
      open_issues : int;
      open_issues_count : int;
      organization : Nullable_simple_user.t option; [@default None]
      owner : Simple_user.t;
      parent : Repository.t option; [@default None]
      permissions : Permissions.t option; [@default None]
      private_ : bool; [@key "private"]
      pulls_url : string;
      pushed_at : string;
      releases_url : string;
      security_and_analysis : Security_and_analysis.t option; [@default None]
      size : int;
      source : Repository.t option; [@default None]
      ssh_url : string;
      stargazers_count : int;
      stargazers_url : string;
      statuses_url : string;
      subscribers_count : int;
      subscribers_url : string;
      subscription_url : string;
      svn_url : string;
      tags_url : string;
      teams_url : string;
      temp_clone_token : string option; [@default None]
      template_repository : Nullable_repository.t option; [@default None]
      topics : Topics.t option; [@default None]
      trees_url : string;
      updated_at : string;
      url : string;
      visibility : string option; [@default None]
      watchers : int;
      watchers_count : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Minimal_repository = struct
  module Primary = struct
    module License_ = struct
      module Primary = struct
        type t = {
          key : string option; [@default None]
          name : string option; [@default None]
          node_id : string option; [@default None]
          spdx_id : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Permissions = struct
      module Primary = struct
        type t = {
          admin : bool option; [@default None]
          maintain : bool option; [@default None]
          pull : bool option; [@default None]
          push : bool option; [@default None]
          triage : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Topics = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      allow_forking : bool option; [@default None]
      archive_url : string;
      archived : bool option; [@default None]
      assignees_url : string;
      blobs_url : string;
      branches_url : string;
      clone_url : string option; [@default None]
      code_of_conduct : Code_of_conduct.t option; [@default None]
      collaborators_url : string;
      comments_url : string;
      commits_url : string;
      compare_url : string;
      contents_url : string;
      contributors_url : string;
      created_at : string option; [@default None]
      default_branch : string option; [@default None]
      delete_branch_on_merge : bool option; [@default None]
      deployments_url : string;
      description : string option;
      disabled : bool option; [@default None]
      downloads_url : string;
      events_url : string;
      fork : bool;
      forks : int option; [@default None]
      forks_count : int option; [@default None]
      forks_url : string;
      full_name : string;
      git_commits_url : string;
      git_refs_url : string;
      git_tags_url : string;
      git_url : string option; [@default None]
      has_downloads : bool option; [@default None]
      has_issues : bool option; [@default None]
      has_pages : bool option; [@default None]
      has_projects : bool option; [@default None]
      has_wiki : bool option; [@default None]
      homepage : string option; [@default None]
      hooks_url : string;
      html_url : string;
      id : int;
      is_template : bool option; [@default None]
      issue_comment_url : string;
      issue_events_url : string;
      issues_url : string;
      keys_url : string;
      labels_url : string;
      language : string option; [@default None]
      languages_url : string;
      license : License_.t option; [@default None]
      merges_url : string;
      milestones_url : string;
      mirror_url : string option; [@default None]
      name : string;
      network_count : int option; [@default None]
      node_id : string;
      notifications_url : string;
      open_issues : int option; [@default None]
      open_issues_count : int option; [@default None]
      owner : Simple_user.t;
      permissions : Permissions.t option; [@default None]
      private_ : bool; [@key "private"]
      pulls_url : string;
      pushed_at : string option; [@default None]
      releases_url : string;
      size : int option; [@default None]
      ssh_url : string option; [@default None]
      stargazers_count : int option; [@default None]
      stargazers_url : string;
      statuses_url : string;
      subscribers_count : int option; [@default None]
      subscribers_url : string;
      subscription_url : string;
      svn_url : string option; [@default None]
      tags_url : string;
      teams_url : string;
      temp_clone_token : string option; [@default None]
      template_repository : Nullable_repository.t option; [@default None]
      topics : Topics.t option; [@default None]
      trees_url : string;
      updated_at : string option; [@default None]
      url : string;
      visibility : string option; [@default None]
      watchers : int option; [@default None]
      watchers_count : int option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Team_repository = struct
  module Primary = struct
    module Permissions = struct
      module Primary = struct
        type t = {
          admin : bool;
          maintain : bool option; [@default None]
          pull : bool;
          push : bool;
          triage : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Topics = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      allow_auto_merge : bool; [@default false]
      allow_forking : bool; [@default false]
      allow_merge_commit : bool; [@default true]
      allow_rebase_merge : bool; [@default true]
      allow_squash_merge : bool; [@default true]
      archive_url : string;
      archived : bool; [@default false]
      assignees_url : string;
      blobs_url : string;
      branches_url : string;
      clone_url : string;
      collaborators_url : string;
      comments_url : string;
      commits_url : string;
      compare_url : string;
      contents_url : string;
      contributors_url : string;
      created_at : string option;
      default_branch : string;
      delete_branch_on_merge : bool; [@default false]
      deployments_url : string;
      description : string option;
      disabled : bool;
      downloads_url : string;
      events_url : string;
      fork : bool;
      forks : int;
      forks_count : int;
      forks_url : string;
      full_name : string;
      git_commits_url : string;
      git_refs_url : string;
      git_tags_url : string;
      git_url : string;
      has_downloads : bool; [@default true]
      has_issues : bool; [@default true]
      has_pages : bool;
      has_projects : bool; [@default true]
      has_wiki : bool; [@default true]
      homepage : string option;
      hooks_url : string;
      html_url : string;
      id : int;
      is_template : bool; [@default false]
      issue_comment_url : string;
      issue_events_url : string;
      issues_url : string;
      keys_url : string;
      labels_url : string;
      language : string option;
      languages_url : string;
      license : Nullable_license_simple.t option;
      master_branch : string option; [@default None]
      merges_url : string;
      milestones_url : string;
      mirror_url : string option;
      name : string;
      network_count : int option; [@default None]
      node_id : string;
      notifications_url : string;
      open_issues : int;
      open_issues_count : int;
      owner : Nullable_simple_user.t option;
      permissions : Permissions.t option; [@default None]
      private_ : bool; [@default false] [@key "private"]
      pulls_url : string;
      pushed_at : string option;
      releases_url : string;
      size : int;
      ssh_url : string;
      stargazers_count : int;
      stargazers_url : string;
      statuses_url : string;
      subscribers_count : int option; [@default None]
      subscribers_url : string;
      subscription_url : string;
      svn_url : string;
      tags_url : string;
      teams_url : string;
      temp_clone_token : string option; [@default None]
      template_repository : Nullable_repository.t option; [@default None]
      topics : Topics.t option; [@default None]
      trees_url : string;
      updated_at : string option;
      url : string;
      visibility : string; [@default "public"]
      watchers : int;
      watchers_count : int;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Nullable_minimal_repository = struct
  module Primary = struct
    module License_ = struct
      module Primary = struct
        type t = {
          key : string option; [@default None]
          name : string option; [@default None]
          node_id : string option; [@default None]
          spdx_id : string option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Permissions = struct
      module Primary = struct
        type t = {
          admin : bool option; [@default None]
          maintain : bool option; [@default None]
          pull : bool option; [@default None]
          push : bool option; [@default None]
          triage : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Topics = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      allow_forking : bool option; [@default None]
      archive_url : string;
      archived : bool option; [@default None]
      assignees_url : string;
      blobs_url : string;
      branches_url : string;
      clone_url : string option; [@default None]
      code_of_conduct : Code_of_conduct.t option; [@default None]
      collaborators_url : string;
      comments_url : string;
      commits_url : string;
      compare_url : string;
      contents_url : string;
      contributors_url : string;
      created_at : string option; [@default None]
      default_branch : string option; [@default None]
      delete_branch_on_merge : bool option; [@default None]
      deployments_url : string;
      description : string option;
      disabled : bool option; [@default None]
      downloads_url : string;
      events_url : string;
      fork : bool;
      forks : int option; [@default None]
      forks_count : int option; [@default None]
      forks_url : string;
      full_name : string;
      git_commits_url : string;
      git_refs_url : string;
      git_tags_url : string;
      git_url : string option; [@default None]
      has_downloads : bool option; [@default None]
      has_issues : bool option; [@default None]
      has_pages : bool option; [@default None]
      has_projects : bool option; [@default None]
      has_wiki : bool option; [@default None]
      homepage : string option; [@default None]
      hooks_url : string;
      html_url : string;
      id : int;
      is_template : bool option; [@default None]
      issue_comment_url : string;
      issue_events_url : string;
      issues_url : string;
      keys_url : string;
      labels_url : string;
      language : string option; [@default None]
      languages_url : string;
      license : License_.t option; [@default None]
      merges_url : string;
      milestones_url : string;
      mirror_url : string option; [@default None]
      name : string;
      network_count : int option; [@default None]
      node_id : string;
      notifications_url : string;
      open_issues : int option; [@default None]
      open_issues_count : int option; [@default None]
      owner : Simple_user.t;
      permissions : Permissions.t option; [@default None]
      private_ : bool; [@key "private"]
      pulls_url : string;
      pushed_at : string option; [@default None]
      releases_url : string;
      size : int option; [@default None]
      ssh_url : string option; [@default None]
      stargazers_count : int option; [@default None]
      stargazers_url : string;
      statuses_url : string;
      subscribers_count : int option; [@default None]
      subscribers_url : string;
      subscription_url : string;
      svn_url : string option; [@default None]
      tags_url : string;
      teams_url : string;
      temp_clone_token : string option; [@default None]
      template_repository : Nullable_repository.t option; [@default None]
      topics : Topics.t option; [@default None]
      trees_url : string;
      updated_at : string option; [@default None]
      url : string;
      visibility : string option; [@default None]
      watchers : int option; [@default None]
      watchers_count : int option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Timeline_line_commented_event = struct
  module Primary = struct
    module Comments = struct
      type t = Pull_request_review_comment.t list
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      comments : Comments.t option; [@default None]
      event : string option; [@default None]
      node_id : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Timeline_commit_commented_event = struct
  module Primary = struct
    module Comments = struct
      type t = Commit_comment.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      comments : Comments.t option; [@default None]
      commit_id : string option; [@default None]
      event : string option; [@default None]
      node_id : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_alert_items = struct
  module Primary = struct
    type t = {
      created_at : string;
      dismissed_at : string option;
      dismissed_by : Nullable_simple_user.t option;
      dismissed_reason : Code_scanning_alert_dismissed_reason.t option;
      html_url : string;
      instances_url : string;
      most_recent_instance : Code_scanning_alert_instance.t;
      number : int;
      rule : Code_scanning_alert_rule_summary.t;
      state : Code_scanning_alert_state.t;
      tool : Code_scanning_analysis_tool.t;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_scanning_alert = struct
  module Primary = struct
    type t = {
      created_at : string;
      dismissed_at : string option;
      dismissed_by : Nullable_simple_user.t option;
      dismissed_reason : Code_scanning_alert_dismissed_reason.t option;
      html_url : string;
      instances_url : string;
      most_recent_instance : Code_scanning_alert_instance.t;
      number : int;
      rule : Code_scanning_alert_rule.t;
      state : Code_scanning_alert_state.t;
      tool : Code_scanning_analysis_tool.t;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Check_run = struct
  module Primary = struct
    module Check_suite_ = struct
      module Primary = struct
        type t = { id : int } [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Conclusion = struct
      let t_of_yojson = function
        | `String "success" -> Ok "success"
        | `String "failure" -> Ok "failure"
        | `String "neutral" -> Ok "neutral"
        | `String "cancelled" -> Ok "cancelled"
        | `String "skipped" -> Ok "skipped"
        | `String "timed_out" -> Ok "timed_out"
        | `String "action_required" -> Ok "action_required"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Output = struct
      module Primary = struct
        type t = {
          annotations_count : int;
          annotations_url : string;
          summary : string option;
          text : string option;
          title : string option;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Pull_requests = struct
      type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Status_ = struct
      let t_of_yojson = function
        | `String "queued" -> Ok "queued"
        | `String "in_progress" -> Ok "in_progress"
        | `String "completed" -> Ok "completed"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      app : Nullable_integration.t option;
      check_suite : Check_suite_.t option;
      completed_at : string option;
      conclusion : Conclusion.t option;
      deployment : Deployment_simple.t option; [@default None]
      details_url : string option;
      external_id : string option;
      head_sha : string;
      html_url : string option;
      id : int;
      name : string;
      node_id : string;
      output : Output.t;
      pull_requests : Pull_requests.t;
      started_at : string option;
      status : Status_.t;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Issue_event_for_issue = struct
  type t =
    | V0 of Labeled_issue_event.t
    | V1 of Unlabeled_issue_event.t
    | V2 of Assigned_issue_event.t
    | V3 of Unassigned_issue_event.t
    | V4 of Milestoned_issue_event.t
    | V5 of Demilestoned_issue_event.t
    | V6 of Renamed_issue_event.t
    | V7 of Review_requested_issue_event.t
    | V8 of Review_request_removed_issue_event.t
    | V9 of Review_dismissed_issue_event.t
    | V10 of Locked_issue_event.t
    | V11 of Added_to_project_issue_event.t
    | V12 of Moved_column_in_project_issue_event.t
    | V13 of Removed_from_project_issue_event.t
    | V14 of Converted_note_to_issue_issue_event.t
  [@@deriving show]

  let of_yojson =
    Json_schema.any_of
      (let open CCResult in
      [
        (fun v -> map (fun v -> V0 v) (Labeled_issue_event.of_yojson v));
        (fun v -> map (fun v -> V1 v) (Unlabeled_issue_event.of_yojson v));
        (fun v -> map (fun v -> V2 v) (Assigned_issue_event.of_yojson v));
        (fun v -> map (fun v -> V3 v) (Unassigned_issue_event.of_yojson v));
        (fun v -> map (fun v -> V4 v) (Milestoned_issue_event.of_yojson v));
        (fun v -> map (fun v -> V5 v) (Demilestoned_issue_event.of_yojson v));
        (fun v -> map (fun v -> V6 v) (Renamed_issue_event.of_yojson v));
        (fun v -> map (fun v -> V7 v) (Review_requested_issue_event.of_yojson v));
        (fun v -> map (fun v -> V8 v) (Review_request_removed_issue_event.of_yojson v));
        (fun v -> map (fun v -> V9 v) (Review_dismissed_issue_event.of_yojson v));
        (fun v -> map (fun v -> V10 v) (Locked_issue_event.of_yojson v));
        (fun v -> map (fun v -> V11 v) (Added_to_project_issue_event.of_yojson v));
        (fun v -> map (fun v -> V12 v) (Moved_column_in_project_issue_event.of_yojson v));
        (fun v -> map (fun v -> V13 v) (Removed_from_project_issue_event.of_yojson v));
        (fun v -> map (fun v -> V14 v) (Converted_note_to_issue_issue_event.of_yojson v));
      ])

  let to_yojson = function
    | V0 v -> Labeled_issue_event.to_yojson v
    | V1 v -> Unlabeled_issue_event.to_yojson v
    | V2 v -> Assigned_issue_event.to_yojson v
    | V3 v -> Unassigned_issue_event.to_yojson v
    | V4 v -> Milestoned_issue_event.to_yojson v
    | V5 v -> Demilestoned_issue_event.to_yojson v
    | V6 v -> Renamed_issue_event.to_yojson v
    | V7 v -> Review_requested_issue_event.to_yojson v
    | V8 v -> Review_request_removed_issue_event.to_yojson v
    | V9 v -> Review_dismissed_issue_event.to_yojson v
    | V10 v -> Locked_issue_event.to_yojson v
    | V11 v -> Added_to_project_issue_event.to_yojson v
    | V12 v -> Moved_column_in_project_issue_event.to_yojson v
    | V13 v -> Removed_from_project_issue_event.to_yojson v
    | V14 v -> Converted_note_to_issue_issue_event.to_yojson v
end

module Branch_protection = struct
  module Primary = struct
    module Allow_deletions = struct
      module Primary = struct
        type t = { enabled : bool option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Allow_force_pushes = struct
      module Primary = struct
        type t = { enabled : bool option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Required_conversation_resolution = struct
      module Primary = struct
        type t = { enabled : bool option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Required_linear_history = struct
      module Primary = struct
        type t = { enabled : bool option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Required_signatures = struct
      module Primary = struct
        type t = {
          enabled : bool;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Required_status_checks = struct
      module Primary = struct
        module Contexts = struct
          type t = string list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          contexts : Contexts.t;
          contexts_url : string option; [@default None]
          enforcement_level : string option; [@default None]
          strict : bool option; [@default None]
          url : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      allow_deletions : Allow_deletions.t option; [@default None]
      allow_force_pushes : Allow_force_pushes.t option; [@default None]
      enabled : bool option; [@default None]
      enforce_admins : Protected_branch_admin_enforced.t option; [@default None]
      name : string option; [@default None]
      protection_url : string option; [@default None]
      required_conversation_resolution : Required_conversation_resolution.t option; [@default None]
      required_linear_history : Required_linear_history.t option; [@default None]
      required_pull_request_reviews : Protected_branch_pull_request_review.t option; [@default None]
      required_signatures : Required_signatures.t option; [@default None]
      required_status_checks : Required_status_checks.t option; [@default None]
      restrictions : Branch_restriction_policy.t option; [@default None]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Event = struct
  module Primary = struct
    module Payload = struct
      module Primary = struct
        module Pages = struct
          module Items = struct
            module Primary = struct
              type t = {
                action : string option; [@default None]
                html_url : string option; [@default None]
                page_name : string option; [@default None]
                sha : string option; [@default None]
                summary : string option; [@default None]
                title : string option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = {
          action : string option; [@default None]
          comment : Issue_comment.t option; [@default None]
          issue : Issue.t option; [@default None]
          pages : Pages.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Repo = struct
      module Primary = struct
        type t = {
          id : int;
          name : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Actor.t;
      created_at : string option;
      id : string;
      org : Actor.t option; [@default None]
      payload : Payload.t;
      public : bool;
      repo : Repo.t;
      type_ : string option; [@key "type"]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Issue_event = struct
  module Primary = struct
    type t = {
      actor : Nullable_simple_user.t option;
      assignee : Nullable_simple_user.t option; [@default None]
      assigner : Nullable_simple_user.t option; [@default None]
      author_association : Author_association.t option; [@default None]
      commit_id : string option;
      commit_url : string option;
      created_at : string;
      dismissed_review : Issue_event_dismissed_review.t option; [@default None]
      event : string;
      id : int;
      issue : Issue.t option; [@default None]
      label : Issue_event_label.t option; [@default None]
      lock_reason : string option; [@default None]
      milestone : Issue_event_milestone.t option; [@default None]
      node_id : string;
      performed_via_github_app : Nullable_integration.t option; [@default None]
      project_card : Issue_event_project_card.t option; [@default None]
      rename : Issue_event_rename.t option; [@default None]
      requested_reviewer : Nullable_simple_user.t option; [@default None]
      requested_team : Team.t option; [@default None]
      review_requester : Nullable_simple_user.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Timeline_cross_referenced_event = struct
  module Primary = struct
    module Source = struct
      module Primary = struct
        type t = {
          issue : Issue.t option; [@default None]
          type_ : string option; [@default None] [@key "type"]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      actor : Simple_user.t option; [@default None]
      created_at : string;
      event : string;
      source : Source.t;
      updated_at : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Combined_commit_status = struct
  module Primary = struct
    module Statuses = struct
      type t = Simple_commit_status.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      commit_url : string;
      repository : Minimal_repository.t;
      sha : string;
      state : string;
      statuses : Statuses.t;
      total_count : int;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Repository_invitation = struct
  module Primary = struct
    module Permissions = struct
      let t_of_yojson = function
        | `String "read" -> Ok "read"
        | `String "write" -> Ok "write"
        | `String "admin" -> Ok "admin"
        | `String "triage" -> Ok "triage"
        | `String "maintain" -> Ok "maintain"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      created_at : string;
      expired : bool option; [@default None]
      html_url : string;
      id : int;
      invitee : Nullable_simple_user.t option;
      inviter : Nullable_simple_user.t option;
      node_id : string;
      permissions : Permissions.t;
      repository : Minimal_repository.t;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Organization_secret_scanning_alert = struct
  module Primary = struct
    type t = {
      created_at : string option; [@default None]
      html_url : string option; [@default None]
      locations_url : string option; [@default None]
      number : int option; [@default None]
      repository : Minimal_repository.t option; [@default None]
      resolution : Secret_scanning_alert_resolution.t option; [@default None]
      resolved_at : string option; [@default None]
      resolved_by : Nullable_simple_user.t option; [@default None]
      secret : string option; [@default None]
      secret_type : string option; [@default None]
      state : Secret_scanning_alert_state.t option; [@default None]
      url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Check_suite_preference = struct
  module Primary = struct
    module Preferences = struct
      module Primary = struct
        module Auto_trigger_checks = struct
          module Items = struct
            module Primary = struct
              type t = {
                app_id : int;
                setting : bool;
              }
              [@@deriving yojson { strict = false; meta = true }, show]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
        end

        type t = { auto_trigger_checks : Auto_trigger_checks.t option [@default None] }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      preferences : Preferences.t;
      repository : Minimal_repository.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Workflow_run = struct
  module Primary = struct
    module Pull_requests = struct
      type t = Pull_request_minimal.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      artifacts_url : string;
      cancel_url : string;
      check_suite_id : int option; [@default None]
      check_suite_node_id : string option; [@default None]
      check_suite_url : string;
      conclusion : string option;
      created_at : string;
      event : string;
      head_branch : string option;
      head_commit : Nullable_simple_commit.t option;
      head_repository : Minimal_repository.t;
      head_repository_id : int option; [@default None]
      head_sha : string;
      html_url : string;
      id : int;
      jobs_url : string;
      logs_url : string;
      name : string option; [@default None]
      node_id : string;
      previous_attempt_url : string option; [@default None]
      pull_requests : Pull_requests.t option;
      repository : Minimal_repository.t;
      rerun_url : string;
      run_attempt : int option; [@default None]
      run_number : int;
      run_started_at : string option; [@default None]
      status : string option;
      updated_at : string;
      url : string;
      workflow_id : int;
      workflow_url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Code_search_result_item = struct
  module Primary = struct
    module Line_numbers = struct
      type t = string list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      file_size : int option; [@default None]
      git_url : string;
      html_url : string;
      language : string option; [@default None]
      last_modified_at : string option; [@default None]
      line_numbers : Line_numbers.t option; [@default None]
      name : string;
      path : string;
      repository : Minimal_repository.t;
      score : float;
      sha : string;
      text_matches : Search_result_text_matches.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Thread = struct
  module Primary = struct
    module Subject = struct
      module Primary = struct
        type t = {
          latest_comment_url : string;
          title : string;
          type_ : string; [@key "type"]
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      id : string;
      last_read_at : string option;
      reason : string;
      repository : Minimal_repository.t;
      subject : Subject.t;
      subscription_url : string;
      unread : bool;
      updated_at : string;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Check_suite = struct
  module Primary = struct
    module Conclusion = struct
      let t_of_yojson = function
        | `String "success" -> Ok "success"
        | `String "failure" -> Ok "failure"
        | `String "neutral" -> Ok "neutral"
        | `String "cancelled" -> Ok "cancelled"
        | `String "skipped" -> Ok "skipped"
        | `String "timed_out" -> Ok "timed_out"
        | `String "action_required" -> Ok "action_required"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Pull_requests = struct
      type t = Pull_request_minimal.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Status_ = struct
      let t_of_yojson = function
        | `String "queued" -> Ok "queued"
        | `String "in_progress" -> Ok "in_progress"
        | `String "completed" -> Ok "completed"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      after : string option;
      app : Nullable_integration.t option;
      before : string option;
      check_runs_url : string;
      conclusion : Conclusion.t option;
      created_at : string option;
      head_branch : string option;
      head_commit : Simple_commit.t;
      head_sha : string;
      id : int;
      latest_check_runs_count : int;
      node_id : string;
      pull_requests : Pull_requests.t option;
      repository : Minimal_repository.t;
      status : Status_.t option;
      updated_at : string option;
      url : string option;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Commit_search_result_item = struct
  module Primary = struct
    module Commit_ = struct
      module Primary = struct
        module Author = struct
          module Primary = struct
            type t = {
              date : string;
              email : string;
              name : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Tree = struct
          module Primary = struct
            type t = {
              sha : string;
              url : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          author : Author.t;
          comment_count : int;
          committer : Nullable_git_user.t option;
          message : string;
          tree : Tree.t;
          url : string;
          verification : Verification.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    module Parents = struct
      module Items = struct
        module Primary = struct
          type t = {
            html_url : string option; [@default None]
            sha : string option; [@default None]
            url : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      author : Nullable_simple_user.t option;
      comments_url : string;
      commit : Commit_.t;
      committer : Nullable_git_user.t option;
      html_url : string;
      node_id : string;
      parents : Parents.t;
      repository : Minimal_repository.t;
      score : float;
      sha : string;
      text_matches : Search_result_text_matches.t option; [@default None]
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Package = struct
  module Primary = struct
    module Package_type = struct
      let t_of_yojson = function
        | `String "npm" -> Ok "npm"
        | `String "maven" -> Ok "maven"
        | `String "rubygems" -> Ok "rubygems"
        | `String "docker" -> Ok "docker"
        | `String "nuget" -> Ok "nuget"
        | `String "container" -> Ok "container"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    module Visibility = struct
      let t_of_yojson = function
        | `String "private" -> Ok "private"
        | `String "public" -> Ok "public"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    type t = {
      created_at : string;
      html_url : string;
      id : int;
      name : string;
      owner : Nullable_simple_user.t option; [@default None]
      package_type : Package_type.t;
      repository : Nullable_minimal_repository.t option; [@default None]
      updated_at : string;
      url : string;
      version_count : int;
      visibility : Visibility.t;
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Short_branch = struct
  module Primary = struct
    module Commit_ = struct
      module Primary = struct
        type t = {
          sha : string;
          url : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      commit : Commit_.t;
      name : string;
      protected : bool;
      protection : Branch_protection.t option; [@default None]
      protection_url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Branch_with_protection = struct
  module Primary = struct
    module Links_ = struct
      module Primary = struct
        type t = {
          html : string;
          self : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = {
      links_ : Links_.t; [@key "_links"]
      commit : Commit.t;
      name : string;
      pattern : string option; [@default None]
      protected : bool;
      protection : Branch_protection.t;
      protection_url : string;
      required_approving_review_count : int option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Timeline_issue_events = struct
  type t =
    | V0 of Labeled_issue_event.t
    | V1 of Unlabeled_issue_event.t
    | V2 of Milestoned_issue_event.t
    | V3 of Demilestoned_issue_event.t
    | V4 of Renamed_issue_event.t
    | V5 of Review_requested_issue_event.t
    | V6 of Review_request_removed_issue_event.t
    | V7 of Review_dismissed_issue_event.t
    | V8 of Locked_issue_event.t
    | V9 of Added_to_project_issue_event.t
    | V10 of Moved_column_in_project_issue_event.t
    | V11 of Removed_from_project_issue_event.t
    | V12 of Converted_note_to_issue_issue_event.t
    | V13 of Timeline_comment_event.t
    | V14 of Timeline_cross_referenced_event.t
    | V15 of Timeline_committed_event.t
    | V16 of Timeline_reviewed_event.t
    | V17 of Timeline_line_commented_event.t
    | V18 of Timeline_commit_commented_event.t
    | V19 of Timeline_assigned_issue_event.t
    | V20 of Timeline_unassigned_issue_event.t
  [@@deriving show]

  let of_yojson =
    Json_schema.any_of
      (let open CCResult in
      [
        (fun v -> map (fun v -> V0 v) (Labeled_issue_event.of_yojson v));
        (fun v -> map (fun v -> V1 v) (Unlabeled_issue_event.of_yojson v));
        (fun v -> map (fun v -> V2 v) (Milestoned_issue_event.of_yojson v));
        (fun v -> map (fun v -> V3 v) (Demilestoned_issue_event.of_yojson v));
        (fun v -> map (fun v -> V4 v) (Renamed_issue_event.of_yojson v));
        (fun v -> map (fun v -> V5 v) (Review_requested_issue_event.of_yojson v));
        (fun v -> map (fun v -> V6 v) (Review_request_removed_issue_event.of_yojson v));
        (fun v -> map (fun v -> V7 v) (Review_dismissed_issue_event.of_yojson v));
        (fun v -> map (fun v -> V8 v) (Locked_issue_event.of_yojson v));
        (fun v -> map (fun v -> V9 v) (Added_to_project_issue_event.of_yojson v));
        (fun v -> map (fun v -> V10 v) (Moved_column_in_project_issue_event.of_yojson v));
        (fun v -> map (fun v -> V11 v) (Removed_from_project_issue_event.of_yojson v));
        (fun v -> map (fun v -> V12 v) (Converted_note_to_issue_issue_event.of_yojson v));
        (fun v -> map (fun v -> V13 v) (Timeline_comment_event.of_yojson v));
        (fun v -> map (fun v -> V14 v) (Timeline_cross_referenced_event.of_yojson v));
        (fun v -> map (fun v -> V15 v) (Timeline_committed_event.of_yojson v));
        (fun v -> map (fun v -> V16 v) (Timeline_reviewed_event.of_yojson v));
        (fun v -> map (fun v -> V17 v) (Timeline_line_commented_event.of_yojson v));
        (fun v -> map (fun v -> V18 v) (Timeline_commit_commented_event.of_yojson v));
        (fun v -> map (fun v -> V19 v) (Timeline_assigned_issue_event.of_yojson v));
        (fun v -> map (fun v -> V20 v) (Timeline_unassigned_issue_event.of_yojson v));
      ])

  let to_yojson = function
    | V0 v -> Labeled_issue_event.to_yojson v
    | V1 v -> Unlabeled_issue_event.to_yojson v
    | V2 v -> Milestoned_issue_event.to_yojson v
    | V3 v -> Demilestoned_issue_event.to_yojson v
    | V4 v -> Renamed_issue_event.to_yojson v
    | V5 v -> Review_requested_issue_event.to_yojson v
    | V6 v -> Review_request_removed_issue_event.to_yojson v
    | V7 v -> Review_dismissed_issue_event.to_yojson v
    | V8 v -> Locked_issue_event.to_yojson v
    | V9 v -> Added_to_project_issue_event.to_yojson v
    | V10 v -> Moved_column_in_project_issue_event.to_yojson v
    | V11 v -> Removed_from_project_issue_event.to_yojson v
    | V12 v -> Converted_note_to_issue_issue_event.to_yojson v
    | V13 v -> Timeline_comment_event.to_yojson v
    | V14 v -> Timeline_cross_referenced_event.to_yojson v
    | V15 v -> Timeline_committed_event.to_yojson v
    | V16 v -> Timeline_reviewed_event.to_yojson v
    | V17 v -> Timeline_line_commented_event.to_yojson v
    | V18 v -> Timeline_commit_commented_event.to_yojson v
    | V19 v -> Timeline_assigned_issue_event.to_yojson v
    | V20 v -> Timeline_unassigned_issue_event.to_yojson v
end
