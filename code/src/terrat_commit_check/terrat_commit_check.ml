module Status = struct
  type t =
    | Queued
    | Running
    | Completed
    | Failed
    | Canceled
  [@@deriving show, eq]
end

type t = {
  details_url : string;
  description : string;
  title : string;
  status : Status.t;
}
[@@deriving make, show, eq]
