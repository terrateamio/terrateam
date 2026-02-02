module Assoc_string_list = struct
  type 'a t = (string * 'a) list [@@deriving show]
end

module String = struct
  include CCMap.Make (CCString)

  let to_yojson f t = `Assoc (CCList.map (fun (k, v) -> (k, f v)) (to_list t))

  let of_yojson f = function
    | `Assoc obj -> (
        try
          Ok
            (CCListLabels.fold_left
               ~f:(fun acc (k, v) ->
                 match f v with
                 | Ok v -> add k v acc
                 | Error err -> failwith err)
               ~init:empty
               obj)
        with Failure err -> Error err)
    | _ -> Error "Expected object"

  let pp f formatter t = Assoc_string_list.pp f formatter (to_list t)
  let show f t = Assoc_string_list.show f (to_list t)
end
