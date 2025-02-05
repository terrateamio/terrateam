module Status = struct
  type t =
    | Approved
    | Unknown
  [@@deriving show, eq]
end

type t = {
  id : string;
  status : Status.t;
  user : string option;
}
[@@deriving show, eq, make]
