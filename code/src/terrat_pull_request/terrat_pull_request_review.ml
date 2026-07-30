module Status = struct
  type t =
    | Approved
    | Unknown
  [@@deriving show, eq]
end

(* The VCS's own verdict on whether the pull request satisfies the required
   reviews for the branch it targets, which is a different question than whether
   any individual review has been approved. *)
module Decision = struct
  type t =
    | Approved
    | Changes_requested
    | Review_required
  [@@deriving show, eq]
end

type t = {
  id : string;
  status : Status.t;
  user : string option;
}
[@@deriving show, eq, make]
