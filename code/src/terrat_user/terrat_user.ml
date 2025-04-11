type t = { id : Uuidm.t } [@@deriving show, eq]

let make ~id () = { id }
let id t = t.id
