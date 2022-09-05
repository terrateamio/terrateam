module Status = struct
  type t =
    | Approved
    | Unknown
  [@@deriving show, eq]
end

type t = {
  id : string;
  status : Status.t;
}
[@@deriving show, eq, make]
