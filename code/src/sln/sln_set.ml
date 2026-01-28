module String = struct
  include CCSet.Make (CCString)

  let to_yojson t = to_list t |> [%to_yojson: string list]

  let of_yojson ls =
    let open CCResult.Infix in
    [%of_yojson: string list] ls >|= of_list

  let dedup_list l = l |> of_list |> to_list
end
