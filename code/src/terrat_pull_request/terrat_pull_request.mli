module State : sig
  module Merged : sig
    type t = {
      merged_hash : string;
      merged_at : string;
    }
    [@@deriving yojson, show]
  end

  module Open_status : sig
    type t =
      | Mergeable
      | Merge_conflict
    [@@deriving yojson, show]
  end

  type t =
    | Open of Open_status.t
    | Closed  (** The PR has been closed without merging *)
    | Merged of Merged.t  (** The PR has been closed by merging, we want the commit id *)
  [@@deriving yojson, show]
end

(** A service-agnostic definition of a pull request. *)
type ('id, 'diff, 'checks, 'repo, 'ref) t [@@deriving yojson, show]

val make :
  base_branch_name:'ref ->
  base_ref:'ref ->
  branch_name:'ref ->
  branch_ref:'ref ->
  checks:'checks ->
  diff:'diff ->
  draft:bool ->
  id:'id ->
  mergeable:bool option ->
  provisional_merge_ref:'ref option ->
  repo:'repo ->
  state:State.t ->
  title:string option ->
  user:string option ->
  unit ->
  ('id, 'diff, 'checks, 'repo, 'ref) t
[@@deriving show]

val base_branch_name : ('id, 'diff, 'checks, 'repo, 'ref) t -> 'ref
val base_ref : ('id, 'diff, 'checks, 'repo, 'ref) t -> 'ref
val branch_name : ('id, 'diff, 'checks, 'repo, 'ref) t -> 'ref
val branch_ref : ('id, 'diff, 'checks, 'repo, 'ref) t -> 'ref
val checks : ('id, 'diff', 'checks, 'repo, 'ref) t -> 'checks
val diff : ('id, 'diff, 'checks, 'repo, 'ref) t -> 'diff
val id : ('id, 'diff, 'checks, 'repo, 'ref) t -> 'id
val is_draft_pr : ('id, 'diff, 'checks, 'repo, 'ref) t -> bool
val mergeable : ('id, 'diff, 'checks, 'repo, 'ref) t -> bool option
val provisional_merge_ref : ('id, 'diff, 'checks, 'repo, 'ref) t -> 'ref option
val repo : ('id, 'diff, 'checks, 'repo, 'ref) t -> 'repo
val state : ('id, 'diff, 'checks, 'repo, 'ref) t -> State.t
val title : ('id, 'diff, 'checks, 'repo, 'ref) t -> string option
val user : ('id, 'diff, 'checks, 'repo, 'ref) t -> string option

val set_diff :
  'diff2 -> ('id, 'diff, 'checks, 'repo, 'ref) t -> ('id, 'diff2, 'checks, 'repo, 'ref) t

val set_checks :
  'checks2 -> ('id, 'diff, 'checks, 'repo, 'ref) t -> ('id, 'diff, 'checks2, 'repo, 'ref) t
