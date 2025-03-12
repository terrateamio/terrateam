module State = struct
  module Merged = struct
    type t = {
      merged_hash : string;
      merged_at : string;
    }
    [@@deriving yojson, show]
  end

  module Open_status = struct
    type t =
      | Mergeable
      | Merge_conflict
    [@@deriving yojson, show]
  end

  type t =
    | Open of Open_status.t
    | Closed
    | Merged of Merged.t
  [@@deriving yojson, show]
end

type ('id, 'diff, 'checks, 'repo, 'ref) t = {
  base_branch_name : 'ref;
  base_ref : 'ref;
  branch_name : 'ref;
  branch_ref : 'ref;
  checks : 'checks;
  diff : 'diff;
  draft : bool;
  id : 'id;
  mergeable : bool option;
  provisional_merge_ref : 'ref option;
  repo : 'repo;
  state : State.t;
  title : string option;
  user : string option;
}
[@@deriving yojson, show]

let make
    ~base_branch_name
    ~base_ref
    ~branch_name
    ~branch_ref
    ~checks
    ~diff
    ~draft
    ~id
    ~mergeable
    ~provisional_merge_ref
    ~repo
    ~state
    ~title
    ~user
    () =
  {
    base_branch_name;
    base_ref;
    branch_name;
    branch_ref;
    checks;
    diff;
    draft;
    id;
    mergeable;
    provisional_merge_ref;
    repo;
    state;
    title;
    user;
  }

let base_branch_name t = t.base_branch_name
let base_ref t = t.base_ref
let branch_name t = t.branch_name
let branch_ref t = t.branch_ref
let checks t = t.checks
let diff t = t.diff
let id t = t.id
let is_draft_pr t = t.draft
let mergeable t = t.mergeable
let provisional_merge_ref t = t.provisional_merge_ref
let pull_number t = t.id
let repo t = t.repo
let state t = t.state
let title t = t.title
let user t = t.user
let set_diff diff t = { t with diff }
let set_checks checks t = { t with checks }
