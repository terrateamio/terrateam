module type S = sig
  type t
  type err

  val start_migration : t -> string -> unit Abb.Future.t
  val complete_migration : t -> string -> unit Abb.Future.t
  val list_migrations : t -> string list -> unit Abb.Future.t
  val get_migrations : t -> (string list, err) result Abb.Future.t
  val add_migration : t -> string -> (unit, err) result Abb.Future.t
end

module Make (M : S) = struct
  type err =
    [ `Migration_err of M.err
    | `Consistency_err
    ]

  module Migration = struct
    type t = M.t -> (unit, M.err) result Abb.Future.t
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

  let rec exec mt = function
    | [] -> Abb.Future.return (Ok ())
    | (name, m) :: ms ->
        let open Abbs_future_combinators.Infix_result_monad in
        start_migration mt name
        >>= fun () ->
        run_migration m mt
        >>= fun () ->
        add_migration mt name >>= fun () -> complete_migration mt name >>= fun () -> exec mt ms

  let rec verify_consistency migrations ms =
    match (migrations, ms) with
    | [], ms -> Some ms
    | mig :: migs, (m, _) :: ms when m = mig -> verify_consistency migs ms
    | _ :: _, _ :: _ | _, [] -> None

  let run mt ms =
    let open Abbs_future_combinators.Infix_result_monad in
    get_migrations mt
    >>= fun migrations ->
    match verify_consistency migrations ms with
    | Some migrations ->
        let open Abb.Future.Infix_monad in
        M.list_migrations mt (CCList.map fst migrations) >>= fun () -> exec mt migrations
    | None -> Abb.Future.return (Error `Consistency_err)
end
