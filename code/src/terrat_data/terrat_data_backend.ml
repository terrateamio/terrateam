module Request = struct end

module Response = struct
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
      webhook_secret : string;
      updated_at : string;
    }
    [@@deriving yojson { strict = false }, show]
  end

  module Env_var = struct
    type t = {
      name : string;
      value : string;
      is_file : bool;
      modified_by : string;
      modified_time : string;
    }
    [@@deriving yojson { strict = false }, show]
  end

  module Env_var_list = struct
    type t = {
      results : Env_var.t list;
      next : string option;
      prev : string option;
    }
    [@@deriving yojson { strict = false }, show]
  end

  module Secret = struct
    type t = {
      name : string;
      encrypted_value : string;
      session_key : string;
      nonce : string;
      is_file : bool;
      modified_by : string;
      modified_time : string;
    }
    [@@deriving yojson { strict = false }, show]
  end

  module Secret_list = struct
    type t = {
      results : Secret.t list;
      next : string option;
      prev : string option;
    }
    [@@deriving yojson { strict = false }, show]
  end
end
