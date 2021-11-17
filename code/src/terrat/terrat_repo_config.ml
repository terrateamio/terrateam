module String_map = CCMap.Make (CCString)

module Autoplan = struct
  type t = {
    enabled : bool;
    when_modified : string list;
  }

  let default = { enabled = true; when_modified = [ "**/*.tf"; "**/*.tfvars" ] }

  let make ?(enabled = true) ?(when_modified = [ "**/*.tf"; "**/*.tfvars" ]) () =
    { enabled; when_modified }
end

module Checkout_strategy = struct
  type t =
    [ `Merge
    | `Branch
    ]
end

module Apply_requirements = struct
  type t =
    [ `Mergable
    | `Approved
    | `Undiverged
    ]
end

module Cost_estimation = struct
  type t = {
    enabled : bool;
    notify_on : string;
  }

  let default = { enabled = true; notify_on = "whatever" }

  let make ?(enabled = true) ?(notify_on = "whatever") () = { enabled; notify_on }
end

module Drift_detection_schedule = struct
  type t = {
    enabled : bool;
    interval : [ `Weekly | `Monthly ];
    notification : string;
  }

  let make ?(enabled = false) ?(interval = `Monthly) ?(notification = "foo") () =
    { enabled; interval; notification }
end

module Notifications = struct
  module Slack = struct
    type t = {
      token : string;
      channels : string list;
      triggers : string list;
    }

    let make token channels triggers = { token; channels; triggers }
  end

  module Webhook = struct
    type t = {
      url : Uri.t;
      headers : (string * string) list;
      triggers : string list;
    }

    let make url headers triggers = { url; headers; triggers }
  end

  module Pagerduty = struct
    type t = { token : string }

    let make token = { token }
  end

  module Github_comments = struct
    type t = {
      verbosity : int;
      enabled : bool;
    }

    let make ?(verbosity = 3) ?(enabled = true) () = { verbosity; enabled }
  end

  type t = {
    slack : Slack.t option;
    webhook : Webhook.t option;
    pagerduty : Pagerduty.t option;
    github_comments : Github_comments.t;
  }

  let default =
    {
      slack = None;
      webhook = None;
      pagerduty = None;
      github_comments = Github_comments.{ verbosity = 3; enabled = true };
    }

  let make ?slack ?webhook ?pagerduty ?(github_comments = Github_comments.make ()) () =
    { slack; webhook; pagerduty; github_comments }
end

module Pre_hook = struct
  type t = { cmd : string list }

  let make cmd = { cmd }
end

module Post_hook = struct
  type t = {
    cmd : string list;
    run_on : [ `Success | `Failure | `Always ]; [@default `Success]
  }

  let make ?(run_on = `Success) cmd = { cmd; run_on }
end

module Hooks = struct
  type t = {
    pre_workflow : Pre_hook.t list;
    pre_plan : Pre_hook.t list;
    post_plan : Post_hook.t list;
    pre_apply : Pre_hook.t list;
    post_apply : Post_hook.t list;
  }

  let make
      ?(pre_workflow = [])
      ?(pre_plan = [])
      ?(post_plan = [])
      ?(pre_apply = [])
      ?(post_apply = [])
      () =
    { pre_workflow; pre_plan; post_plan; pre_apply; post_apply }
end

module Permissions = struct
  module Rbac = struct
    type t = {
      id : string;
      permission : [ `Allow | `Deny ];
    }

    let make id permission = { id; permission }
  end

  type t = {
    plan : Rbac.t list; [@default [ Rbac.{ id = "*"; permission = `Allow } ]]
    apply : Rbac.t list; [@default [ Rbac.{ id = "*"; permission = `Allow } ]]
    key_rotation : Rbac.t list; [@default [ Rbac.{ id = "*"; permission = `Deny } ]]
    fetch_state : Rbac.t list; [@default [ Rbac.{ id = "*"; permission = `Deny } ]]
    unlock : Rbac.t list; [@default [ Rbac.{ id = "*"; permission = `Allow } ]]
  }

  let default =
    {
      plan = [ Rbac.{ id = "*"; permission = `Allow } ];
      apply = [ Rbac.{ id = "*"; permission = `Allow } ];
      key_rotation = [ Rbac.{ id = "*"; permission = `Deny } ];
      fetch_state = [ Rbac.{ id = "*"; permission = `Deny } ];
      unlock = [ Rbac.{ id = "*"; permission = `Allow } ];
    }

  let make
      ?(plan = [ Rbac.{ id = "*"; permission = `Allow } ])
      ?(apply = [ Rbac.{ id = "*"; permission = `Allow } ])
      ?(key_rotation = [ Rbac.{ id = "*"; permission = `Deny } ])
      ?(fetch_state = [ Rbac.{ id = "*"; permission = `Deny } ])
      ?(unlock = [ Rbac.{ id = "*"; permission = `Allow } ])
      () =
    { plan; apply; key_rotation; fetch_state; unlock }
end

module Context = struct
  module Dir = struct
    type t = {
      dir : string;
      workspace : string; [@default "default"]
      terraform_version : string option; [@default None]
      autoplan : Autoplan.t option; [@default None]
      apply_requirements : Apply_requirements.t list option; [@default None]
      cost_estimation : Cost_estimation.t option; [@default None]
      hooks : Hooks.t option; [@default None]
      permissions : string option; [@default None]
    }

    let make
        ?(workspace = "default")
        ?terraform_version
        ?autoplan
        ?apply_requirements
        ?cost_estimation
        ?hooks
        ?permissions
        dir =
      {
        dir;
        workspace;
        terraform_version;
        autoplan;
        apply_requirements;
        cost_estimation;
        hooks;
        permissions;
      }
  end

  type t = {
    dirs : Dir.t list;
    workspace : string; [@default "default"]
    terraform_version : string option; [@default None]
    autoplan : Autoplan.t option; [@default None]
    apply_requirements : Apply_requirements.t list option; [@default None]
    cost_estimation : Cost_estimation.t option; [@default None]
    hooks : Hooks.t option; [@default None]
    permissions : string option; [@default None]
  }

  let make
      ?(workspace = "default")
      ?terraform_version
      ?autoplan
      ?apply_requirements
      ?cost_estimation
      ?hooks
      ?permissions
      dirs =
    {
      dirs;
      workspace;
      terraform_version;
      autoplan;
      apply_requirements;
      cost_estimation;
      hooks;
      permissions;
    }
end

type t = {
  enabled : bool; [@default true]
  version : int;
  tf_state_dir_pattern_list : string list; [@default [ "**/*.tf" ]]
  module_dir_fragements : string list; [@default [ "modules" ]]
  automerge : bool; [@default false]
  autoplan : Autoplan.t; [@default Autoplan.default]
  checkout_strategy : Checkout_strategy.t; [@default `Merge]
  default_tf_version : string; [@default "latest"]
  apply_requirements : Apply_requirements.t list; [@default [ `Mergable ]]
  cost_estimation : Cost_estimation.t; [@default Cost_estimation.default]
  drift_detection_schedule : Drift_detection_schedule.t option; [@default None]
  notifications : Notifications.t; [@default Notifications.default]
  hooks : Hooks.t option; [@default None]
  permissions : Permissions.t String_map.t;
  default_permissions : string; [@default "default"]
  contexts : Context.t String_map.t;
}

let make
    ?(enabled = true)
    ?(tf_state_dir_pattern_list = [ "**/*.tf" ])
    ?(module_dir_fragements = [ "modules" ])
    ?(automerge = false)
    ?(autoplan = Autoplan.make ())
    ?(checkout_strategy = `Merge)
    ?(default_tf_version = "latest")
    ?(apply_requirements = [ `Mergable ])
    ?(cost_estimation = Cost_estimation.make ())
    ?drift_detection_schedule
    ?(notifications = Notifications.make ())
    ?hooks
    ?(permissions = String_map.of_list [ ("default", Permissions.make ()) ])
    ?(default_permissions = "default")
    ?(contexts = String_map.empty)
    version =
  {
    enabled;
    version;
    tf_state_dir_pattern_list;
    module_dir_fragements;
    automerge;
    autoplan;
    checkout_strategy;
    default_tf_version;
    apply_requirements;
    cost_estimation;
    drift_detection_schedule;
    notifications;
    hooks;
    permissions;
    default_permissions;
    contexts;
  }

module Cases = struct
  let default = make 1

  let default_team_apply =
    {
      default with
      permissions =
        String_map.of_list
          [
            ( "default",
              Permissions.(make ~apply:[ Rbac.{ id = "team:sre"; permission = `Allow } ] ()) );
          ];
    }

  let default_dir_permissions =
    {
      default with
      permissions =
        String_map.of_list
          [
            ("default", Permissions.make ());
            ("ops", Permissions.(make ~apply:[ Rbac.{ id = "team:sre"; permission = `Allow } ] ()));
          ];
      contexts =
        String_map.of_list
          [ ("iam", Context.make ~permissions:"ops" Context.Dir.[ make "production/iam" ]) ];
    }

  let example =
    make
      ~permissions:
        (String_map.of_list
           [
             ("default", Permissions.make ());
             ("ops", Permissions.(make ~apply:[ Rbac.{ id = "team:sre"; permission = `Allow } ] ()));
           ])
      ~contexts:
        (String_map.of_list
           [
             ( "production",
               Context.(
                 make
                   ~permissions:"ops"
                   Dir.
                     [
                       make ~workspace:"prod-us-west-1" "aws/ec2";
                       make ~workspace:"prod-us-east-1" "aws/ec2";
                     ]) );
             ( "staging",
               Context.(
                 make
                   Dir.
                     [
                       make ~workspace:"staging-us-west-1" "aws/ec2";
                       make ~workspace:"staging-us-east-1" "aws/ec2";
                     ]) );
           ])
      1
end
