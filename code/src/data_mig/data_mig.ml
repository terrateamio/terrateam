module Error = struct
  type 'a t =
    [ `Migration_err of 'a
    | `Consistency_err
    ]
end

module type S = sig
  type tx
  type 'a t
  type err

  val tx :
    'a t -> (tx t -> ('r, err Error.t) result Abb.Future.t) -> ('r, err Error.t) result Abb.Future.t

  val start_migration : tx t -> string -> unit Abb.Future.t
  val complete_migration : tx t -> string -> unit Abb.Future.t
  val list_migrations : 'a t -> string list -> unit Abb.Future.t
  val get_migrations : tx t -> (string list, err) result Abb.Future.t
  val add_migration : tx t -> string -> (unit, err) result Abb.Future.t
end

module Make (M : S) = struct
  type err = M.err Error.t

  module Migration = struct
    type t = M.tx M.t -> (unit, M.err) result Abb.Future.t
  end

  let run_migration m mt =
    let open Abb.Future.Infix_monad in
    m mt
    >>| function
    | Ok () -> Ok ()
    | Error err -> Error (`Migration_err err)

  let get_migrations mt =
    let open Abb.Future.Infix_monad in
    M.get_migrations mt
    >>| function
    | Ok ms -> Ok ms
    | Error err -> Error (`Migration_err err)

  let add_migration mt name =
    let open Abb.Future.Infix_monad in
    M.add_migration mt name
    >>| function
    | Ok () -> Ok ()
    | Error err -> Error (`Migration_err err)

  let start_migration mt name =
    let open Abb.Future.Infix_monad in
    M.start_migration mt name >>= fun () -> Abb.Future.return (Ok ())

  let complete_migration mt name =
    let open Abb.Future.Infix_monad in
    M.complete_migration mt name >>= fun () -> Abb.Future.return (Ok ())

  let exec mt (name, m) =
    let open Abbs_future_combinators.Infix_result_monad in
    start_migration mt name
    >>= fun () ->
    run_migration m mt >>= fun () -> add_migration mt name >>= fun () -> complete_migration mt name

  let rec verify_consistency migrations ms =
    match (migrations, ms) with
    | [], ms -> Some ms
    | mig :: migs, (m, _) :: ms when m = mig -> verify_consistency migs ms
    | _ :: _, _ :: _ | _, [] -> None

  (* Do each migration one at a time inside a transaction, committing the
     transaction between steps.  This is so that, in the case of a database, we
     don't build up a massive transaction.  It also means, in the case of a
     database which has concurrent processes performing migrations, each
     migration step will be serialized but it might bounce around between
     processes.  That's OK. *)
  let rec run' mt ms =
    let open Abbs_future_combinators.Infix_result_monad in
    M.tx mt (fun tx ->
        get_migrations tx
        >>= function
        | migrations -> (
            match verify_consistency migrations ms with
            | Some [] -> Abb.Future.return (Ok `Done)
            | Some (migration :: _) ->
                let open Abb.Future.Infix_monad in
                M.list_migrations tx [ fst migration ]
                >>= fun () ->
                let open Abbs_future_combinators.Infix_result_monad in
                exec tx migration >>= fun () -> Abb.Future.return (Ok `Cont)
            | None -> Abb.Future.return (Error `Consistency_err)))
    >>= function
    | `Done -> Abb.Future.return (Ok ())
    | `Cont -> run' mt ms

  let run mt ms =
    (run' mt ms : (unit, err) result Abb.Future.t :> (unit, [> err ]) result Abb.Future.t)
end
