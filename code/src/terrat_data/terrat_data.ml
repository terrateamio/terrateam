module Assoc_string_list = struct
  type 'a t = (string * 'a) list [@@deriving show]
end

module String_map = struct
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

module String_set = CCSet.Make (CCString)

module Assoc_dirspace_list = struct
  type 'a t = (Terrat_dirspace.t * 'a) list [@@deriving show]
end

module Dirspace_map = struct
  include CCMap.Make (Terrat_dirspace)

  let to_yojson f t =
    `Assoc
      (CCList.map
         (fun ({ Terrat_dirspace.dir; workspace }, v) -> (dir ^ ":" ^ workspace, f v))
         (to_list t))

  let of_yojson f = function
    | `Assoc obj -> (
        try
          Ok
            (CCListLabels.fold_left
               ~f:(fun acc (k, v) ->
                 match f v with
                 | Ok v -> (
                     match CCString.Split.right ~by:":" k with
                     | Some (dir, workspace) -> add { Terrat_dirspace.dir; workspace } v acc
                     | None -> failwith ("Invalid key:" ^ k))
                 | Error err -> failwith err)
               ~init:empty
               obj)
        with Failure err -> Error err)
    | _ -> Error "Expected object"

  let pp f formatter t = Assoc_dirspace_list.pp f formatter (to_list t)
  let show f t = Assoc_dirspace_list.show f (to_list t)
end

module Dirspace_set = CCSet.Make (Terrat_dirspace)

module type GROUP_BY = sig
  type t
  type key

  val compare : key -> key -> int
  val key : t -> key
end

module Group_by (G : GROUP_BY) = struct
  module Map = CCMap.Make (struct
    type t = G.key

    let compare = G.compare
  end)

  let group l =
    let m =
      CCListLabels.fold_left
        ~init:Map.empty
        ~f:(fun m t ->
          let key = G.key t in
          match Map.find_opt key m with
          | Some v -> Map.add key (t :: v) m
          | None -> Map.add key [ t ] m)
        l
    in
    Map.fold (fun k v acc -> (k, CCList.rev v) :: acc) m []
end
