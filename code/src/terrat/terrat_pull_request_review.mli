module Status : sig
  type t =
    | Approved
    | Unknown
end
[@@deriving show, eq]

type t = {
  id : string;
  status : Status.t;
}
[@@deriving show, eq, make]
