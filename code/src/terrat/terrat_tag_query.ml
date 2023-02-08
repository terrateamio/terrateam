type t = Terrat_tag_set.t [@@deriving show]

let of_string = Terrat_tag_set.of_string
let to_string = Terrat_tag_set.to_string
let match_ t ts = Terrat_tag_set.match_ ~query:t ts
