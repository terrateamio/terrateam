type t = {
  avatar_url : string option;
  email : string option;
  id : Uuidm.t;
  name : string option;
}
[@@deriving show, eq]

module Sql = struct end

let make ?email ?name ?avatar_url ~id () = { avatar_url; email; id; name }
let avatar_url t = t.avatar_url
let email t = t.email
let id t = t.id
let name t = t.name
let enforce_installation_access storage user installation_id ctx = failwith "nyi"
