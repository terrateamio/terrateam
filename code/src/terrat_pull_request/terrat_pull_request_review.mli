module Status : sig
  type t =
    | Approved
    | Unknown
end
[@@deriving show, eq]

module Decision : sig
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
