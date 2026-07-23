module Abb = Abb_scheduler_select
module Oth_abb = Oth_abb.Make (Abb)
module Fut = Abb.Future
module Fc = Abb_future_combinators.Make (Fut)
module Exec = Abb_bounded_suspendable_executor.Make (Abb) (CCString)

module Hmap = Hmap.Make (struct
  type 'a t = string
end)

(* This test drives the Chan-based bounded suspendable executor through the
   [Buildsys] machinery against the real [Abb_scheduler_select] scheduler. The
   build futures resolve when the build completes, so we simply await them rather
   than synchronously stepping the scheduler. *)

module Builder = struct
  module Key_repr = struct
    type t = {
      key : Hmap.Key.t;
      name : string;
    }

    let equal a b = Hmap.Key.equal a.key b.key
    let to_string k = k.name
  end

  type 'v k = 'v Hmap.key

  let key_repr_of_key k = { Key_repr.key = Hmap.Key.hide_type k; name = Hmap.Key.info k }

  module C = struct
    type 'a t = 'a Fut.t

    let return = Fut.return
    let ( >>= ) = Fut.Infix_monad.( >>= )
    let with_finally f ~finally = Fc.with_finally f ~finally
  end

  module Queue = struct
    type t = Exec.t

    let run ~name t f = Exec.run ~name:[ Key_repr.to_string name ] t f
    let suspend ~name t = Exec.suspend ~name:[ Key_repr.to_string name ] t
    let unsuspend ~name t = Exec.unsuspend ~name:[ Key_repr.to_string name ] t
  end

  module Notify = struct
    type t = (unit Fut.t * unit Fut.Promise.t) ref

    let create () =
      let p = Fut.Promise.create () in
      ref (Fut.Promise.future p, p)

    let notify t =
      let open Fut.Infix_monad in
      let _, notify = !t in
      let p = Fut.Promise.create () in
      t := (Fut.Promise.future p, p);
      Fut.Promise.set notify () >>= fun () -> Fut.return ()

    let wait t =
      let open Fut.Infix_monad in
      let wait, _ = !t in
      wait >>= fun () -> Fut.return ()
  end

  module State = struct
    type t = Hmap.t ref

    let set_k t k v =
      t := Hmap.add k v !t;
      C.return ()

    let get_k t k =
      match Hmap.find k !t with
      | Some v -> C.return v
      | None -> failwith "Key not found"

    let get_k_opt t k = C.return (Hmap.find k !t)
  end
end

module Bs = Buildsys.Make (Builder)

external coerce : 'a Hmap.key -> 'a Bs.Task.t Hmap.key = "%identity"

let rebuilder = { Bs.Rebuilder.run = (fun _st _k _v -> Builder.C.return false) }

let test_const =
  Oth_abb.test ~name:"Const" (fun () ->
      let open Fut.Infix_monad in
      let a1 : int Hmap.key = Hmap.Key.create "a1" in
      let state = Hmap.empty |> Hmap.add a1 10 in
      let st = Bs.St.create (ref state) in
      let tasks_map = Hmap.empty in
      let tasks =
        { Bs.Tasks.get = (fun _ k -> Builder.C.return (Hmap.find (coerce k) tasks_map)) }
      in
      Exec.create ~slots:10 ()
      >>= fun queue ->
      Bs.build queue rebuilder tasks a1 st
      >>= fun result ->
      assert (result = 10);
      assert (Bs.St.running_count st = 0);
      assert (Bs.St.blocking_count st = 0);
      Fut.return ())

let test_dynamic_dependency =
  Oth_abb.test ~name:"Dynamic dependency" (fun () ->
      let open Fut.Infix_monad in
      (* b1 fetches a1 and adds one. This exercises a task fetching another
         through the executor-backed queue. *)
      let a1 : int Hmap.key = Hmap.Key.create "a1" in
      let b1 : int Hmap.key = Hmap.Key.create "b1" in
      let st = Bs.St.create (ref Hmap.empty) in
      let tasks_map =
        Hmap.empty
        |> Hmap.add (coerce a1) (fun _ _ _ -> Builder.C.return 10)
        |> Hmap.add (coerce b1) (fun _ _ { Bs.Fetcher.fetch } ->
            fetch a1 >>= fun v -> Fut.return (v + 1))
      in
      let tasks =
        { Bs.Tasks.get = (fun _ k -> Builder.C.return (Hmap.find (coerce k) tasks_map)) }
      in
      Exec.create ~slots:10 ()
      >>= fun queue ->
      Bs.build queue rebuilder tasks b1 st
      >>= fun result ->
      assert (result = 11);
      assert (Bs.St.running_count st = 0);
      assert (Bs.St.blocking_count st = 0);
      Fut.return ())

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ Oth_abb.(to_sync_test (serial [ test_const; test_dynamic_dependency ]))
