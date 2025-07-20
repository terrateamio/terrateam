module Excel = struct
  module Key_repr = struct
    type t = Hmap.Key.t

    let equal = Hmap.Key.equal
    let to_string _ = "<fill in>"
  end

  type 'v k = 'v Hmap.key

  let key_repr_of_key = Hmap.Key.hide_type

  module C = struct
    type 'a t = 'a

    let return = CCFun.id
    let ( >>= ) v f = f v
    let protect f = f ()
  end

  module Notify = struct
    type t = unit

    let create () = ()
    let notify () = C.return ()
    let wait () = C.return ()
  end

  module State = struct
    type t = unit

    let set_k _ _ _ = ()
    let get_k _ _ = raise (Failure "nyi")
    let get_k_opt _ _ = None
  end
end

module Bs = Buildsys.Make (Excel)

external coerce : 'a Hmap.key -> 'a Bs.Task.t Hmap.key = "%identity"

let rebuilder = { Bs.Rebuilder.run = (fun st _k _v -> false) }

let test_const =
  Oth.test ~name:"const" (fun _ ->
      let a1 : int Hmap.key = Hmap.Key.create () in
      let st = Bs.St.create () in
      let tasks_map = Hmap.empty |> Hmap.add (coerce a1) (fun _ _ _ -> 10) in
      let tasks = { Bs.Tasks.get = (fun _ k -> Hmap.find (coerce k) tasks_map) } in
      let ret = Bs.build rebuilder tasks a1 st in
      assert (ret = 10))

let test_dynamic =
  Oth.test ~name:"dynamic" (fun _ ->
      let a1 : int Hmap.key = Hmap.Key.create () in
      let b1 : int Hmap.key = Hmap.Key.create () in
      let st = Bs.St.create () in
      let tasks_map =
        Hmap.empty
        |> Hmap.add (coerce a1) (fun _ _ _ -> 10)
        |> Hmap.add (coerce b1) (fun _ _ { Bs.Fetcher.fetch } -> fetch a1 + 1)
      in
      let tasks = { Bs.Tasks.get = (fun _ k -> Hmap.find (coerce k) tasks_map) } in
      let ret = Bs.build rebuilder tasks b1 st in
      assert (ret = 11))

let test_dynamic2 =
  Oth.test ~name:"dynamic2" (fun _ ->
      let a1 : int Hmap.key = Hmap.Key.create () in
      let b1 : int Hmap.key = Hmap.Key.create () in
      let b2 : int Hmap.key = Hmap.Key.create () in
      let st = Bs.St.create () in
      let tasks_map =
        Hmap.empty
        |> Hmap.add (coerce a1) (fun _ _ _ -> 10)
        |> Hmap.add (coerce b1) (fun _ _ { Bs.Fetcher.fetch } -> fetch a1 + 1)
        |> Hmap.add (coerce b2) (fun _ _ { Bs.Fetcher.fetch } -> fetch a1 + fetch b1)
      in
      let tasks = { Bs.Tasks.get = (fun _ k -> Hmap.find (coerce k) tasks_map) } in
      let ret = Bs.build rebuilder tasks b2 st in
      assert (ret = 21))

let test = Oth.parallel [ test_const; test_dynamic; test_dynamic2 ]

let () =
  Random.self_init ();
  Oth.run test
