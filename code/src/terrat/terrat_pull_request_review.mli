module Status : sig
  type t =
    | Approved
    | Unknown
end
[@@deriving show, eq]

type t = {
  id : string;
  status : Status.t;
  user : string option;
}
[@@deriving show, eq, make]
