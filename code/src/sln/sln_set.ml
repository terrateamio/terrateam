module String = struct
  include CCSet.Make (CCString)

  type t_list = string list [@@deriving show]

  let to_yojson t = to_list t |> [%to_yojson: string list]

  let of_yojson ls =
    let open CCResult.Infix in
    [%of_yojson: string list] ls >|= of_list

  let pp fmt t = pp_t_list fmt (to_list t)
  let show t = show_t_list (to_list t)
  let dedup_list l = l |> of_list |> to_list
end
