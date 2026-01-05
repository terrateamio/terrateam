module Excel = struct
  module Key_repr = struct
    type t = Hmap.Key.t

    let equal = Hmap.Key.equal
    let to_string _ = "<fill in>"
  end

  type 'v k = 'v Hmap.key

  let key_repr_of_key = Hmap.Key.hide_type

  module C = struct
    type 'a t = 'a option

    let return = CCOption.return
    let ( >>= ) = CCOption.( >>= )
    let protect f = Some (f ())
  end

  module Notify = struct
    type t = unit

    let create () = ()
    let notify () = C.return ()
    let wait () = C.return ()
  end

  module State = struct
    type t = Hmap.t ref

    let set_k t k v =
      t := Hmap.add k v !t;
      C.return ()

    let get_k t k = Hmap.find k !t
    let get_k_opt t k = C.return @@ Hmap.find k !t
  end
end

module Bs = Buildsys.Make (Excel)

external coerce : 'a Hmap.key -> 'a Bs.Task.t Hmap.key = "%identity"

let rebuilder = { Bs.Rebuilder.run = (fun st _k _v -> Excel.C.return false) }

let test_const =
  Oth.test ~name:"const" (fun _ ->
      let a1 : int Hmap.key = Hmap.Key.create () in
      let state = Hmap.empty |> Hmap.add a1 10 in
      let st = Bs.St.create (ref state) in
      let tasks_map = Hmap.empty in
      let tasks =
        { Bs.Tasks.get = (fun _ k -> Excel.C.return @@ Hmap.find (coerce k) tasks_map) }
      in
      let ret = Bs.build rebuilder tasks a1 st in
      assert (ret = Some 10))

let test_dynamic =
  Oth.test ~name:"dynamic" (fun _ ->
      let a1 : int Hmap.key = Hmap.Key.create () in
      let b1 : int Hmap.key = Hmap.Key.create () in
      let state = Hmap.empty |> Hmap.add a1 10 in
      let st = Bs.St.create (ref state) in
      let tasks_map =
        Hmap.empty
        |> Hmap.add (coerce b1) (fun _ _ { Bs.Fetcher.fetch } ->
               let open Excel.C in
               fetch a1 >>= fun a1 -> Excel.C.return (a1 + 1))
      in
      let tasks =
        { Bs.Tasks.get = (fun _ k -> Excel.C.return @@ Hmap.find (coerce k) tasks_map) }
      in
      let ret = Bs.build rebuilder tasks b1 st in
      assert (ret = Some 11))

let test_dynamic2 =
  Oth.test ~name:"dynamic2" (fun _ ->
      let a1 : int Hmap.key = Hmap.Key.create () in
      let b1 : int Hmap.key = Hmap.Key.create () in
      let b2 : int Hmap.key = Hmap.Key.create () in
      let state = Hmap.empty |> Hmap.add a1 10 in
      let st = Bs.St.create (ref state) in
      let tasks_map =
        Hmap.empty
        |> Hmap.add (coerce b1) (fun _ _ { Bs.Fetcher.fetch } ->
               let open Excel.C in
               fetch a1 >>= fun a1 -> Excel.C.return (a1 + 1))
        |> Hmap.add (coerce b2) (fun _ _ { Bs.Fetcher.fetch } ->
               let open Excel.C in
               fetch a1 >>= fun a1 -> fetch b1 >>= fun b1 -> Excel.C.return (a1 + b1))
      in
      let tasks =
        { Bs.Tasks.get = (fun _ k -> Excel.C.return @@ Hmap.find (coerce k) tasks_map) }
      in
      let ret = Bs.build rebuilder tasks b2 st in
      assert (ret = Some 21))

let test_key_does_not_exist =
  Oth.test ~name:"Key does not exist" (fun _ ->
      let a1 : int Hmap.key = Hmap.Key.create () in
      let state = Hmap.empty in
      let st = Bs.St.create (ref state) in
      let tasks_map = Hmap.empty in
      let tasks =
        { Bs.Tasks.get = (fun _ k -> Excel.C.return @@ Hmap.find (coerce k) tasks_map) }
      in
      let ret = Bs.build rebuilder tasks a1 st in
      assert (ret = None))

let test = Oth.parallel [ test_const; test_dynamic; test_dynamic2; test_key_does_not_exist ]

let () =
  Random.self_init ();
  Oth.run test
