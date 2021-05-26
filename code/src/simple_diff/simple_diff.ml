module type Comparable = sig
  type t

  val compare : t -> t -> int
end

module type S = sig
  type item

  type diff =
    | Deleted of item array
    | Added   of item array
    | Equal   of item array

  type t = diff list

  val get_diff : item array -> item array -> t
end

module Make (Item : Comparable) = struct
  type item = Item.t

  type diff =
    | Deleted of item array
    | Added   of item array
    | Equal   of item array

  type t = diff list

  let shortest_edit old revised =
    let old_len = Array.length old in
    let revised_len = Array.length revised in
    let max = old_len + revised_len in

    let v = Array.make ((2 * max) + 1) Int.max_int in

    v.(max + 1) <- 0;

    let rec outer trace = function
      | d when d = max -> trace
      | d -> (
          let rec inner k =
            if k <= d then (
              let x =
                if k = -d || (k <> d && v.(max + k - 1) < v.(max + k + 1)) then
                  v.(max + k + 1)
                else
                  v.(max + k - 1) + 1
              in
              let y = x - k in
              let rec nested x y =
                if x < old_len && y < revised_len && 0 = Item.compare old.(x) revised.(y) then
                  nested (x + 1) (y + 1)
                else
                  (x, y)
              in
              let (x, y) = nested x y in
              v.(max + k) <- x;
              if x >= old_len && y >= revised_len then
                `Stop d
              else
                inner (k + 2)
            ) else
              `Cont
          in
          let trace = Array.copy v :: trace in
          match inner (-d) with
            | `Cont   -> outer trace (d + 1)
            | `Stop _ -> trace)
    in
    outer [] 0

  let backtrack old revised trace =
    let old_len = Array.length old in
    let revised_len = Array.length revised in
    let max = old_len + revised_len in

    let rec outer track x y d = function
      | []      -> track
      | v :: vs ->
          let k = x - y in
          let prev_k =
            if k = -d || (k <> d && v.(max + k - 1) < v.(max + k + 1)) then
              k + 1
            else
              k - 1
          in
          let prev_x = v.(max + prev_k) in
          assert (prev_x <> Int.max_int);
          let prev_y = prev_x - prev_k in

          let rec inner track x y =
            if x > prev_x && y > prev_y then
              inner ((x - 1, y - 1, x, y) :: track) (x - 1) (y - 1)
            else if d > 0 then
              ((prev_x, prev_y, x, y) :: track, prev_x, prev_y)
            else
              (track, prev_x, prev_y)
          in

          let (track, x, y) = inner track x y in
          outer track x y (d - 1) vs
    in
    outer [] old_len revised_len (List.length trace - 1) trace

  let rec compact acc cacc vs =
    match (cacc, vs) with
      | (cacc, [])                      -> List.rev (cacc :: acc)
      | (Equal eqs, Equal v :: vs)      -> compact acc (Equal (Array.append eqs v)) vs
      | (Added adds, Added v :: vs)     -> compact acc (Added (Array.append adds v)) vs
      | (Deleted dels, Deleted v :: vs) -> compact acc (Deleted (Array.append dels v)) vs
      | (cacc, v :: vs)                 -> compact (cacc :: acc) v vs

  let get_diff old revised =
    let trace = shortest_edit old revised in
    let track = backtrack old revised trace in
    let expanded =
      List.map
        (function
          | (prev_x, prev_y, x, _) when prev_x = x -> Added [| revised.(prev_y) |]
          | (prev_x, prev_y, _, y) when prev_y = y -> Deleted [| old.(prev_x) |]
          | (_, prev_y, _, _) -> Equal [| revised.(prev_y) |])
        track
    in
    match expanded with
      | []      -> []
      | v :: vs -> compact [] v vs
end
