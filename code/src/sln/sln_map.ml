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
  let keys_set m = keys m |> Iter.to_list |> Sln_set.String.of_list
end

module Uuidm = struct
  include CCMap.Make (Uuidm)

  let by_uuidm_lists pairs =
    CCList.fold_left (fun acc (k, v) -> add_to_list k v acc) empty pairs |> bindings
end
