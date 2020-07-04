module Std_list = ListLabels

module Make (Fut : Abb_intf.Future.S) = struct
  open Fut.Infix_monad

  module List = struct
    let rec fold_left ~f ~init = function
      | []      -> Fut.return init
      | l :: ls -> f init l >>= fun acc -> fold_left ~f ~init:acc ls

    let map ~f l =
      fold_left ~f:(fun acc l -> f l >>= fun v -> Fut.return (v :: acc)) ~init:[] l
      >>= fun l -> Fut.return (Std_list.rev l)

    let iter ~f l = fold_left ~f:(fun () l -> f l) ~init:() l

    let filter ~f l =
      fold_left
        ~f:(fun acc v ->
          f v
          >>= function
          | true  -> Fut.return (v :: acc)
          | false -> Fut.return acc)
        ~init:[]
        l
      >>| fun ls -> List.rev ls
  end

  let link f1 f2 =
    Fut.add_dep ~dep:f1 f2;
    Fut.add_dep ~dep:f2 f1

  let unit = Fut.return ()

  let ignore fut = fut >>= fun _ -> unit

  let background fut = ignore (Fut.fork fut)

  let first f1 f2 =
    let p = Fut.Promise.create () in
    link f1 (Fut.Promise.future p);
    link f2 (Fut.Promise.future p);
    Fut.fork (f1 >>= fun v -> Fut.Promise.set p (v, f2))
    >>= fun r1 ->
    Fut.fork (f2 >>= fun v -> Fut.Promise.set p (v, f1))
    >>= fun r2 ->
    Fut.fork (r1 >>= fun () -> Fut.cancel r2)
    >>= fun _ -> Fut.fork (r2 >>= fun () -> Fut.cancel r1) >>= fun _ -> Fut.Promise.future p

  let firstl l =
    let p = Fut.Promise.create () in
    Std_list.iter ~f:(fun dep -> link dep (Fut.Promise.future p)) l;
    let futl = Std_list.mapi ~f:(fun idx fut -> fut >>= fun v -> Fut.Promise.set p (idx, v)) l in
    List.iter ~f:(fun fut -> ignore (Fut.fork fut)) futl
    >>= fun () ->
    Fut.Promise.future p
    >>= fun (idx, v) ->
    let (_, rest_rev) =
      Std_list.fold_left
        ~f:(fun (i, l) fut ->
          if i = idx then
            (i + 1, l)
          else
            (i + 1, fut :: l))
        ~init:(0, [])
        l
    in
    (* Cancel those other ones *)
    List.iter ~f:Fut.cancel futl >>| fun () -> (v, Std_list.rev rest_rev)

  let all l =
    let fut = List.map ~f:(fun x -> x) l in
    Std_list.iter ~f:(fun d -> link d fut) l;
    fut

  let with_finally f ~finally =
    try
      let fut = f () in
      let p = Fut.Promise.create ~abort:finally () in
      Fut.add_dep ~dep:fut (Fut.Promise.future p);
      Fut.fork
        (Fut.await_bind
           (fun r ->
             match r with
               | `Det v   -> finally () >>= fun () -> Fut.Promise.set p v
               | `Exn exn -> Fut.Promise.set_exn p exn
               | `Aborted -> Fut.abort (Fut.Promise.future p))
           fut)
      >>= fun _ -> Fut.Promise.future p
    with exn ->
      finally ()
      >>= fun () ->
      let p = Fut.Promise.create () in
      Fut.Promise.set_exn p (exn, Some (Printexc.get_raw_backtrace ()))
      >>= fun () -> Fut.Promise.future p

  let on_failure f ~failure =
    let succeeded = ref false in
    with_finally
      (fun () ->
        f ()
        >>| fun ret ->
        succeeded := true;
        ret)
      ~finally:(fun () ->
        if not !succeeded then
          failure ()
        else
          unit)

  let to_result fut = fut >>= fun v -> Fut.return (Ok v)

  let of_option = function
    | Some fut -> fut >>| fun r -> Some r
    | None     -> Fut.return None

  module Infix_result_monad = struct
    type ('a, 'b) t = ('a, 'b) result Fut.t

    let ( >>= ) t f =
      t
      >>= function
      | Ok v           -> f v
      | Error _ as err -> Fut.return err

    let ( >>| ) t f =
      t
      >>| function
      | Ok v           -> Ok (f v)
      | Error _ as err -> err
  end
end
