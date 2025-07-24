module Context = struct
  module Scope = struct
    type ('pr, 'branch) t =
      | Pull_request of 'pr
      | Branch of 'branch
      | Setup
    [@@deriving show, eq]
  end

  type ('pr, 'branch) t = {
    created_at : string;
    id : Uuidm.t;
    scope : ('pr, 'branch) Scope.t;
    updated_at : string;
  }
  [@@deriving show, eq]
end

module Job = struct
  module Type_ = struct
    type t =
      | Apply of { tag_query : Terrat_tag_query.t }
      | Autoapply
      | Autoplan
      | Plan of { tag_query : Terrat_tag_query.t }
      | Repo_config
      | Unlock
    [@@deriving show, eq]
  end

  module State = struct
    type t =
      | Running
      | Completed
      | Failed
    [@@deriving show, eq]
  end

  type ('pr, 'branch, 'user) t = {
    completed_at : string option;
    context : ('pr, 'branch) Context.t;
    created_at : string;
    id : Uuidm.t;
    initiator : 'user;
    state : State.t;
    type_ : Type_.t;
    updated_at : string;
  }
  [@@deriving show, eq]
end
