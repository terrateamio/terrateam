module Request = struct
  module Config = struct
    type t = {
      allow_draft_pr : bool option; [@default None]
      auto_merge_after_apply : bool option; [@default None]
      autoplan_file_list : string list option; [@default None]
      default_terraform_version : string option option; [@default Some None]
      enable_apply : bool option; [@default None]
      enable_apply_all : bool option; [@default None]
      enable_autoplan : bool option; [@default None]
      enable_diff_markdown_format : bool option; [@default None]
      enable_local_merge_dest_branch_before_plan : bool option; [@default None]
      enable_repo_locking : bool option; [@default None]
      enable_terragrunt : bool option; [@default None]
      require_approval : bool option; [@default None]
      require_mergeable : bool option; [@default None]
    }
    [@@deriving yojson, show, eq]
  end

  module Env_var = struct
    type t = {
      name : string;
      value : string;
      is_file : bool;
    }
    [@@deriving yojson, show, eq]
  end

  module Secret = struct
    type t = {
      name : string;
      value : string;
      is_file : bool;
    }
    [@@deriving yojson, show, eq]
  end

  module User_prefs = struct
    type t = { receive_marketing_emails : bool option [@default None] }
    [@@deriving yojson, show, eq]
  end
end

module Response = struct
  module Oauth_config = struct
    type t = { url : string } [@@deriving yojson { strict = false }, show, eq]
  end

  module Whoami = struct
    type t = {
      user_id : string;
      avatar_url : string;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module Installation = struct
    type t = {
      name : string;
      id : string;
      admin : bool;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module Installation_list = struct
    type t = {
      next : string option;
      prev : string option;
      results : Installation.t list;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module Config = struct
    type t = {
      allow_draft_pr : bool;
      auto_merge_after_apply : bool;
      autoplan_file_list : string list;
      default_terraform_version : string option;
      enable_apply : bool;
      enable_apply_all : bool;
      enable_autoplan : bool;
      enable_diff_markdown_format : bool;
      enable_local_merge_dest_branch_before_plan : bool;
      enable_repo_locking : bool;
      enable_terragrunt : bool;
      require_approval : bool;
      require_mergeable : bool;
      updated_at : string;
      updated_by : string option;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module Env_var = struct
    type t = {
      name : string;
      value : string;
      is_file : bool;
      modified_by : string;
      modified_time : string;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module Env_var_list = struct
    type t = {
      results : Env_var.t list;
      next : string option;
      prev : string option;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module Secret = struct
    type t = {
      name : string;
      is_file : bool;
      modified_by : string;
      modified_time : string;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module Secret_list = struct
    type t = {
      results : Secret.t list;
      next : string option;
      prev : string option;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module Session = struct
    type t = {
      created_at : string;
      user_agent : string;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module Session_list = struct
    type t = {
      results : Session.t list;
      next : string option;
      prev : string option;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module Terraform_versions = struct
    type t = {
      default_version : string;
      versions : string list;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end

  module User_prefs = struct
    type t = {
      receive_marketing_emails : bool;
      email : string option;
    }
    [@@deriving yojson { strict = false }, show, eq]
  end
end
