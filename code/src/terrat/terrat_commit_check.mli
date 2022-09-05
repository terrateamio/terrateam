module Status : sig
  type t =
    | Queued
    | Running
    | Completed
    | Failed
  [@@deriving show, eq]
end

type t = {
  details_url : string;
  description : string;
  title : string;
  status : Status.t;
}
[@@deriving make, show, eq]
